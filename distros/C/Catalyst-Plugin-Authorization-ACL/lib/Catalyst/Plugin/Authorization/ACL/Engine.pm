package Catalyst::Plugin::Authorization::ACL::Engine;
BEGIN {
  $Catalyst::Plugin::Authorization::ACL::Engine::AUTHORITY = 'cpan:RKITOVER';
}
$Catalyst::Plugin::Authorization::ACL::Engine::VERSION = '0.16';
use namespace::autoclean;
use Moose;
extends qw/Moose::Object Exporter/;

# I heart stevan
use Class::Throwable;
use Tree::Simple;
use Tree::Simple::Visitor::FindByPath;
use Tree::Simple::Visitor::GetAllDescendents;
use Carp qw/croak/;
use List::Util 'first';

has app     => (is => 'rw');
has actions => (is => 'ro', isa => 'HashRef', default => sub { {} });
has _app_actions_tree => (is => 'ro', isa => 'Tree::Simple', lazy_build => 1);

our $DENIED  = bless {}, __PACKAGE__ . "::Denied";
our $ALLOWED = bless {}, __PACKAGE__ . "::Allowed";

our @EXPORT_OK = qw/$DENIED $ALLOWED/;

sub BUILDARGS {
    my ($self, $c) = @_;
    return +{ app => $c };
}

sub _build__app_actions_tree {
    my $self = shift;
    my $root = Tree::Simple->new('/', Tree::Simple->ROOT);
    my $app  = $self->app;

    my @actions = grep defined, map {
        my $controller = $_;
        map $controller->action_for($_->name), $controller->get_action_methods
    } grep $_->isa('Catalyst::Controller'), values %{ $app->components };

    for my $action (@actions) {
        my @path = split '/', $action->reverse;
        my $name = pop @path;

        if (@path) {
            my $by_path = Tree::Simple::Visitor::FindByPath->new;
            $by_path->setSearchPath(@path);
            $root->accept($by_path);

            if (my $namespace_node = $by_path->getResult) {
                $namespace_node->addChild(Tree::Simple->new($action));
                next;
            }
        }

        my $node = $root;
        for my $el (@path) {
            if (my $found = first { $_->getNodeValue eq $el }
                @{ $node->getAllChildren }) {
                $node = $found;
            }
            else {
                $node = Tree::Simple->new($el, $node);
            }
        }

        $node->addChild(Tree::Simple->new($action));
    }

    return $root;
}

sub add_deny {
    my ( $self, $spec, $condition ) = @_;

    my $test = $self->fudge_condition($condition);

    $self->add_rule(
        $spec,
        sub {
            my $c = shift;
            die $DENIED unless $c->$test(@_);
        },
    );
}

sub add_allow {
    my ( $self, $spec, $condition ) = @_;

    my $test = $self->fudge_condition($condition);

    $self->add_rule(
        $spec,
        sub {
            my $c = shift;
            die $ALLOWED if $c->$test(@_);
        },
    );
}

sub fudge_condition {
    my ( $self, $condition ) = @_;

    # make almost anything into a code ref/method name

    if (!defined($condition)
        # no warnings
        or $condition eq '1'
        or $condition eq '0'
        or $condition eq "" )
    {
        return sub { $condition };
    }
    elsif ( my $reftype = ref $condition ) {
        $reftype eq "CODE" and return $condition;

        # if it's not a code ref and it's a ref, we only know
        # how to deal with it if it's an array of roles
        $reftype ne "ARRAY"
          and die "Can't interpret '$condition' as an ACL condition";

        # but to check roles we need the appropriate plugin
        $self->app->isa("Catalyst::Plugin::Authorization::Roles")
          or die "Can't use role list as an ACL condition unless "
          . "the Authorization::Roles plugin is also loaded.";

        # return a test that will check for the roles
        return sub {
            my $c = shift;
            $c->check_user_roles(@$condition);
        };
    }
    elsif ( $self->app->can($condition) ) {
        return $condition;    # just a method name
    }
    else {
        croak "Can't use '$condition' as an ACL "
          . "condition unless \$c->can('$condition').";
    }
}

sub add_rule {
    my ( $self, $path, $rule, $filter ) = @_;
    $filter ||= sub { $_[0]->name !~ /^_/ };    # internal actions are not ACL'd

    my $d = $self->app->dispatcher;

    my $cxt = _pretty_caller();

    $self->{cxt_info}{$rule} = $cxt;

    my ( $ns, $name ) = $path =~ m#^/?(.*?)/?([^/]+)$#;

    if ( my $action = $d->get_action( $name, $ns ) ) {
        $self->app->log->debug(
            "Adding ACL rule from $cxt to the action $path with sort index 0")
          if $self->app->debug;
        $self->append_rule_to_action( $action, 0, $rule, $cxt );
    }
    else {
        my @path = grep { $_ ne "" } split( "/", $path );
        my $tree = $self->_app_actions_tree;

        my $subtree = @path
          ? do {
            my $by_path = Tree::Simple::Visitor::FindByPath->new;
            $by_path->setSearchPath(@path);
            $tree->accept($by_path);

            $by_path->getResult
              || Catalyst::Exception->throw(
                    "The path '$path' does not exist (traversal hit a dead end "
                  . "at: @{[ map { $_->getNodeValue } $by_path->getResults ]})"
              );
          }
          : $tree;
        my $root_depth = $subtree->getDepth;

        my $descendents = Tree::Simple::Visitor::GetAllDescendents->new;
        $descendents->setNodeFilter( sub { $_[0] } );    #
        $subtree->accept($descendents);

        $self->app->log->debug(
            "Adding ACL rule from $cxt to all the actions under $path")
          if $self->app->debug;

        foreach my $action_node ( $descendents->getResults ) {
            next unless $action_node->isLeaf;

            my ( $action, $depth ) =
              ( $action_node->getNodeValue, $action_node->getDepth );

            next unless $filter->($action);

            my $sort_index =
              ( $depth - $root_depth )
              ;    # how far an action is from the origin of the ACL
            $self->app->log->debug("... $action at sort index $sort_index")
              if $self->app->debug;
            $self->append_rule_to_action( $action, $sort_index, $rule, $cxt,
            );
        }
    }
}

sub get_cxt_for_rule {
    my ( $self, $rule ) = @_;
    $self->{cxt_info}{$rule};
}

sub append_rule_to_action {
    my ( $self, $action, $sort_index, $rule, $cxt ) = @_;
    $sort_index = 0 if $sort_index < 0;
    push @{ $self->get_action_data($action)->{rules_radix}[$sort_index] ||=
          [] }, $rule;

}

sub get_action_data {
    my ( $self, $action ) = @_;
    $self->actions->{ $action->reverse } ||= { action => $action };
}

sub get_rules {
    my ( $self, $action ) = @_;

    map { $_ ? @$_ : () }
      @{ ( $self->get_action_data($action) || return () )->{rules_radix} };
}

sub check_action_rules {
    my ( $self, $c, $action ) = @_;

    my $last_rule;

    my $rule_exception;

    {
        local $SIG{__DIE__}; # nobody messes with us!
        local $@;

        eval {
            foreach my $rule ( $self->get_rules($action) )
            {
                $c->log->debug( "running ACL rule $rule defined at "
                      . $self->get_cxt_for_rule($rule)
                      . " on $action" )
                  if $c->debug;
                $last_rule = $rule;
                $c->$rule($action);
            }
        };

        $rule_exception = $@;
    }

    if ($rule_exception) {
        if ( ref $rule_exception and $rule_exception == $DENIED ) {
            die "Access to $action denied by rule $last_rule (defined at "
              . $self->get_cxt_for_rule($last_rule) . ").\n";
        }
        elsif ( ref $rule_exception and $rule_exception == $ALLOWED ) {
            $c->log->debug(
                    "Access to $action allowed by rule $last_rule (defined at "
                  . $self->get_cxt_for_rule($last_rule)
                  . ")" )
              if $c->debug;
            return;
        }
        else {

            # unknown exception
            # FIXME - add context (the user should know what rule
            # generated the exception, and where it was added)
            Class::Throwable->throw(
                "An error occurred while evaluating ACL rules.", $rule_exception );
        }
    }

    # no rules means allow by default
}

sub _pretty_caller {
    my ( undef, $file, $line ) = _find_caller();
    return "$file line $line";
}

sub _find_caller {
    for ( my $i = 2 ; ; $i++ ) {
        my @caller = caller($i) or die "Error determining caller";
        return @caller if $caller[0] !~ /^Catalyst::Plugin::Authorization::ACL/;
    }
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Authorization::ACL::Engine - The backend that computes ACL
checks for L<Catalyst::Plugin::Authorization::ACL>.

=head1 SYNOPSIS

	# internal

=head1 METHODS

=over 4

=item new $app

Create a new rule engine for $app

=item add_allow $cond

=item add_deny $cond

fudge C<$cond>, make cond into a rule, and C<add_rule>

=item add_rule $path, $rule

Add rule to all actions under $path

=item append_rule_to_action $action, $index, $rule, $cxt

Append C<$rule> to C<$action> in slot C<$index>, and store context info C<$cxt>
for error reporting.

=item check_action_rules $action

Evaluate the rules for an action

=item fudge_condition $thingy

Converts a C<$thingy> into a subref, for DWIM goodness. See the main ACL docs.

=item get_action_data $action

=item get_cxt_for_rule $rule

=item get_rules

=back

=head1 DESCRIPTION

This is the engine which executes the access control checks for
L<Catalyst::Plugin::Authorization::ACL>. Please use that module directly.

=head1 TODO

    * external uris -> private paths

=cut

