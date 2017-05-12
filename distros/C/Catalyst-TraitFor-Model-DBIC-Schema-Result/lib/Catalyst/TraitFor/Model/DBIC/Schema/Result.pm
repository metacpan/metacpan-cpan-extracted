package Catalyst::TraitFor::Model::DBIC::Schema::Result;

use Moose::Role;
use Scalar::Util;

our $VERSION = '0.006';

after '_install_rs_models', sub {
  my $self  = shift;
  my $class = $self->_original_class_name;
 
  no strict 'refs';
  my @sources = $self->schema->sources;
  die "No sources for your schema" unless @sources;

  foreach my $moniker (@sources) {
    my $classname = "${class}::${moniker}::Result";
    *{"${classname}::ACCEPT_CONTEXT"} = sub {
      my ($result_self, $c, @passed_args) = @_;
      my $id = '__' . ref($result_self);

      # Allow one to 'reset' the current IF there's @passed_args.

      delete $c->stash->{$id} if exists($c->stash->{$id}) && scalar(@passed_args);

      return $c->stash->{$id} ||= do {
        my @args = @{$c->request->args};
        my @arg = @{$c->request->args}; # common typo.
        if(my $template = $c->action->attributes->{ResultModelFrom}) {
          @args = (eval " {$template->[0]}");
        }

        ## if the first argument is a resultset of the current model name
        ## then use that instead of a new one.

        my $rs = $c->model($self->model_name)
          ->resultset($moniker);

        if(
          (Scalar::Util::blessed($passed_args[0]||'')) 
            and
          ($passed_args[0]->isa('DBIx::Class::ResultSet'))
            and
          ($passed_args[0]->result_source->source_name eq $moniker)
        ) {
          $c->log->info("Getting Result from existing ResultSet") if $c->debug;
          $rs = shift(@passed_args);
        }



        ## Arguments passed via ->Model take precident.
        my @find = scalar(@passed_args) ? @passed_args : @args;

        my $find;
        if($c->debug) {
          require JSON::MaybeXS;
          my $json_with_args = JSON::MaybeXS->new(utf8 => 1, allow_nonref=>1);
          $find = scalar(@find) ? $json_with_args->encode(@find) : '[NEW RESULT]';
        }

        my $return;
        if(scalar(@find)) {
          if($c->debug) {
            $c->log->info("Finding model via ${\$self->model_name}->$moniker"."::find($find)");
          }
          $return = $rs->find(@find);

          if($c->debug and !$return) {
            $c->log->info("No records for ${\$self->model_name}->$moniker"."::find($find)");
          }
        } else {
          if($c->debug) {
            $c->log->info("No request arguments, returning new_result");
          }
          $return = $rs->new_result(+{});
        }

        return $return;
      };
    };
  }
};

1;

=head1 NAME

Catalyst::TraitFor::Model::DBIC::Schema::Result - PerRequest Result from Catalyst Request

=head1 SYNOPSIS

In your configuration, set the trait:

    MyApp->config(
      'Model::Schema' => {
        traits => ['Result'],
        schema_class => 'MyApp::Schema',
        connect_info => [ ... ],
      },
    );

Now in your actions you can call the generated models, which get their ->find($id) from
$c->request->args.

    sub user :Local Args(1) {
      my ($self, $c, $id) = @_;

      ## Like: $c->model('Schema::User')->find($id)
      my $user = $c->model('Schema::User::Result');
    }

You can also control how the 'find' on the Resultset works via an action attribute
('ResultModelFrom') or via arguments passed to the 'model' call.

    sub user_with_attr :Local Args(1) ResultModelFrom(first_name=>$args[0]) {
      my ($self, $c, @args) = @_;

      ## Like: $c->model('Schema::User')->find({first_name=>$args[0]})
      my $user = $c->model('Schema::User::Result');
    }

If you want to use a resultset that is 'prepared' you can pass it as the first
argument:

    sub from_rs :Local Args(1) {
      my ($self, $c, $id) = @_;
      my $rs = $c->model("Schema::User")->search({first_name=>['john','joe']});
      my $user = $c->model('Schema::User::Result', $rs);
    }

(This feature is probably most useful in a chaining setup.)

Lastly, if you invoke this method on an action the explicitly defines no arguments
you get a new result rather than a database lookup

    sub new_user_result :Local Args(0) {
      my ($self, $c) = @_;

      ## Like: $c->model('Schema::User')->new_result(+{});
      my $new_user_result = $c->model('Schema::User::Result');
    }

=head1 DESCRIPTION

Its a common case to get the result of a L<DBIx::Class> '->find' based on the current
L<Catalyst> request (typically from the Args attribute).  This is an experimental trait
to see if we can usefully encapsulate that common task in a way that is not easily broken.

If you can't read the source code and figure out what is going on, might want to stay
away for now!

When you compose this trait into your MyApp::Model::Schema (subclass of
L<Catalyst::Model::DBIC::Schema>) it automatically creates a second PerRequest model
for each ResultSource in your Schema.  This new Model is named by taking the name
of the resultsource (for example 'Schema::User') and adding '::Result' to it (or
in the example case 'Schema::User::Result').  When you request an instance of this
model, it will automatically assume the arguments of the current action is intended
to be the index by which the ->find locates your database row.  So basically the two
following actions are the same in effect:

With trait:

    sub user :Local Args(1) {
      my ($self, $c, $id) = @_;
      my $user = $c->model('Schema::User::Result');
    }

Without trait:

    sub user :Local Args(1) {
      my ($self, $c, $id) = @_;
      my $user = $c->model('Schema::User')->find($id);
    }

I recommend that if you can use L<Catalyst> 5.9009x+ that you use a type constraint
to make sure the argument is the correct type (otherwise you risk generating a
database error if the user tries to submit a string arg and the database is expecting
an integer:

    use Types::Standard 'Int';

    sub user :Local Args(Int) {
      my ($self, $c) = @_;
      my $user = $c->model('Schema::User::Result');
    }

=head1 SUBROUTINE ATTRIBUTES

For the case when a result is complex (requires more than one argument) or you 
want to use a key other then the PK, you may add a subroutine argument to describe
the pattern:

  sub user_with_attr :Local Args(1) ResultModelFrom(first_name=>$args[0]) {
    my ($self, $c) = @_;
  }

This is experimental and may change as needed.  Basically this get converted
to a hashref and submitted to ->find.

=head1 Actions with no arguments

If you current action has no arguments, we instead return a new result, which
is a DBIC result that is not yet in storage.  You can use this to make a new
row in the database and save it:

    sub new_result :Local Args(0) {
        my ($self, $c) = @_;
        my $new_user = $c->model('Schema::User::Result');
        $new_user->name('Fido');
        $new_user->insert; # Save the new user.
    }

You might find this useful in some common patterns for validating POST parameters
and using them to create a new object in the database.

Please note that you should be quite explicit in setting Args(0) since in many
cases leaving the Args attribute off defaults to 'as many args as you care to
send!

=head1 Passing arguments to ->model

Lastly, you may passing arguments to find via the ->model call.  The following
are examples

With trait:

    sub user :Local Args(1) {
      my ($self, $c) = @_;
      my $user = $c->model('Schema::User::Result', $some_other_id);
    }

Without trait:

    sub user :Local Args(1) {
      my ($self, $c, $id) = @_;
      my $user = $c->model('Schema::User')->find($some_other_id);
    }

With trait:

    sub user :Local Args(1) {
      my ($self, $c) = @_;
      my $user = $c->model('Schema::User::Result', +{first_name=>'john'});
    }

Without trait:

    sub user :Local Args(1) {
      my ($self, $c, $id) = @_;
      my $user = $c->model('Schema::User')->find({first_name=>'john'});
    }

If you choose to pass arguments this way, each call will 'reset' the current
model (changing PerRequest into a Factory type).  This behavior is still
subject to change).

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Model::DBIC::Schema>.

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 COPYRIGHT & LICENSE
 
Copyright 2017, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
