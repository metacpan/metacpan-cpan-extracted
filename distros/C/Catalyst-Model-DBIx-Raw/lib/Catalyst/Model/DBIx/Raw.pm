package Catalyst::Model::DBIx::Raw;
use strict;
use warnings;

use Carp ();
use DBIx::Raw .08;
use Moose;
extends 'Catalyst::Model';
with 'Catalyst::Component::InstancePerContext';
no Moose;

#ABSTRACT: A Catalyst Model for DBIx::Raw

sub new {
	my $self  = shift->next::method(@_);
	my $class = ref($self);
    
	my ($c) = @_;	
	$self->_create_raw($c);
    return $self;
}

sub _create_raw { 
	my ($self, $c) = @_;

	my %options;
	if($self->{dbix_class_model}) { 
		my $model = $c->model($self->{dbix_class_model});
		#catalyst will throw it's own error if model does not exist
		$options{dbh} = $c->model($self->{dbix_class_model})->storage->dbh;
	}
	else { 
		Carp::croak("Must provide either dbix_class_model, or (dsn, user, password), or conf") unless $self->{dbix_class_model}
					or ($self->{dsn} and $self->{user} and $self->{password}) or $self->{conf};
		%options =	(
						dns => $self->{dsn},
						user => $self->{user},
						password => $self->{password},
						conf => $self->{conf},
					);
	}

    # Instantiate a new DBIx::Raw object...
    $self->{raw} = DBIx::Raw->new(%options);
}


sub build_per_context_instance {
	my ($self, $c) = @_;
 
	return $self unless ref $c;

	#reuse same DBIx::Raw object, but get new dbh
    if($self->{dbix_class_model}) { 
		$self->{raw}->dbh($c->model($self->{dbix_class_model})->storage->dbh);
	}
	else { 
		$self->{raw}->connect;
	}

	return $self;
}

sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;
 
    my $program = $AUTOLOAD;
    $program =~ s/.*:://;
 
    # pass straight through to our DBIx::Raw object
	return $self->{raw}->$program(@_);
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Model::DBIx::Raw - A Catalyst Model for DBIx::Raw

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    # Use the helper to add a DBIx::Raw model to your application
    script/myapp_create.pl model Raw DBIx::Raw

    package YourApp::Model::Raw;
    use parent 'Catalyst::Model::DBIx::Raw';

    __PACKAGE__->config(
        dsn => 'dsn',
        user => 'user',
        password => 'password',
    );

    #or
    __PACKAGE__->config(
        conf => '/path/to/conf.pl',
    );

    #or
    __PACKAGE__->config(
        dbix_class_model => 'DB', #will use same dbh as DBIx::Class if you have a DBIx::Class model named 'DB'
    );
 
 
    1;
    
    package YourApp::Controller::Foo;

    sub index : Path('/') {
        my ($self, $c) = @_;
        my $name = $c->model('Raw')->raw("SELECT name FROM people WHERE id=1");
        $c->res->body("Hello, $name!");
    }
 
    1;

=head1 METHODS

=head2 new

L<Catalyst> calls this method.

=head1 CONFIG

L<Catalyst::Model::DBIx::Raw> takes in all of the same options as config options that L<DBIx::Raw> accepts for new. You can use C<dsn>, C<user>, and C<password> to connect:

    __PACKAGE__->config(
        dsn => 'dsn',
        user => 'user',
        password => 'password',
    );

Or you can use a conf file:

    __PACKAGE__->config(
        conf => '/path/to/conf.pl',
    );

See L<DBIx::Raw> for more information on those options. Additionally, there is one new option in L<Catalyst::Model::DBIx::Raw>, and that is C<dbix_class_model>:

    __PACKAGE__->config(
        dbix_class_model => 'DB', 
    );

This is the name of your L<DBIx::Class> model, if you have one. If passed in, L<Catalyst::Model::DBIx::Raw> will reuse the same dbh that L<DBIx::Class> is using. This
can be useful if you have L<DBIx::Class> being used for things such as session management or CRUD with forms, but you are using L<Catalyst::Model::DBIx::Raw> to query yourself. This
way you do not unecessarily create two database handles. Even if you do not use L<DBIx::Class> in a particular call, L<Catalyst::Model::DBIx::Raw> can still use the L<DBIx::Class> model
to get a database handle.

=head1 NOTES

One thing to note is that L<Catalyst::Model::DBIx::Raw> uses the same L<DBIx::Raw> object every request, but gets a new dbh every request using L<DBIx::Raw>'s 
L<connect|DBIx::Raw/"connect"> method.

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
