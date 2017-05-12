package App::Tool::Base;
{
  $App::Tool::Base::VERSION = '0.07';
}

# ABSTRACT: simple framework for command-line utils

use 5.010;
use strict;
use warnings;
use utf8;

use Carp;

use Attribute::Handlers;
use Getopt::Long;


=head1 SYNOPSIS

    # initialize framework and run tool
    use App::Tool::Base qw/ run /;
    run();
    exit 0;

    # describe actions
    sub new
        :Action
        :Descriprion("Create new instance")
        :Argument(name)
    {
        # all arguments and options in plain hash
        my %opt = @_;

        # ... some useful code here
    }

=head1 DESCRIPTION

App::Tool::Base is a simple framework for rapid tool creation.

Here word <tool> means command-line utility that can perform some actions, and has common command-line format:

<utility-name> <action> <arguments and options>

    $ svn checkout $REPO/trunk . -r 888
    $ apt-get install $DEB
    $ docker images

App::Tool::Base provides smart command-line options processing with some checks, and help message generation.

=cut


# action info storage
{
my %action;
my %action_by_method;
my @actions;

sub _add_action {
    my ($info, $names) = @_;

    my @names = ref $names ? @$names : ($names);
    $info->{action} //= $names[0];

    push @actions, $info;
    $action{$_} = $info  for @names;

    if ( my $method = $info->{method} ) {
        $action_by_method{$method} = $info;
    }

    return;
}

sub _get_action_by_method {
    my ($method) = @_;

    my $info = $action_by_method{$method}
        or croak "Action for $method is not defined";

    return $info;
}

sub _get_action_by_name {
    my ($name) = @_;
    my $info = $action{$name}
        or croak "Action $name is not defined";
    return $info;
}

sub _get_actions_list {
    return [grep {!$_->{hidden}} @actions];
}

sub _get_action_names {
    my ($full) = @_;
    my @actions = $full
        ? (sort keys %action)
        : (map {$_->{action}} grep {!$_->{hidden}} @actions);
    return \@actions;
}

}



    
=head1 ATTRIBUTE HANDLERS

=head2 :Action

    sub init :Action { ... some code ... }

    sub recalculate_everything :Action(refresh) { ... }

Registers attributed sub as action worker.

If action name is not defined, sub name will be used

=cut

sub Action :ATTR(CODE, BEGIN) {
    my ($package, $symbol, $referent, $attr, $data, $level, $source, $line) = @_;

    my $method = *{$symbol}{NAME};
    my $action_names = $data || $method;

    my $action_info = {
        method => $method,
        sub => $referent,
        source => $source,
    };

    _add_action($action_info, $action_names);
    return;
}


=head2 :Hidden

    sub init :Action
        :Hidden
    { ... some code ... }

Mark action as hidden.

Hidden actions is not shown in lists, but still can be executed.

=cut

sub Hidden :ATTR(CODE, BEGIN) {
    my ($package, $symbol, $referent, $attr, $data) = @_;
    my $method = *{$symbol}{NAME};
    my $info = _get_action_by_method($method);
    $info->{hidden} = 1;
    return;
}


=head2 :Description

    sub init :Action
        :Description("Initialize workplace")
    { ... some code ... }

Provides brief worker description.

=cut

sub Description :ATTR(CODE, BEGIN) {
    my ($package, $symbol, $referent, $attr, $data) = @_;
    my $method = *{$symbol}{NAME};
    my $info = _get_action_by_method($method);
    $info->{description} = (ref $data ? $data->[0] : $data);
    return;
}


=head2 :Argument

    sub init :Action
        :Argument(name, "workplace name")
    { ... some code ... }

Declares that action has required positional argument

=cut

sub Argument :ATTR(CODE, BEGIN) {
    my ($package, $symbol, $referent, $attr, $data) = @_;
    my $method = *{$symbol}{NAME};
    my $info = _get_action_by_method($method);

    my ($arg, $descr) = (ref $data ? @$data : $data);
    push @{$info->{req_args}}, $arg;
    $info->{arg_descr}->{$arg} = $descr  if $descr;
    return;
}


=head2 :OptionalArgument

    sub init :Action
        :Argument(name, "workplace name")
        :OptionalArgument(template, "name of template")
    { ... some code ... }

Declares that action has optional positional argument

=cut

sub OptionalArgument :ATTR(CODE, BEGIN) {
    my ($package, $symbol, $referent, $attr, $data) = @_;
    my $method = *{$symbol}{NAME};
    my $info = _get_action_by_method($method);

    my ($arg, $descr) = (ref $data ? @$data : $data);
    push @{$info->{opt_args}}, $arg;
    $info->{arg_descr}->{$arg} = $descr  if $descr;
    return;
}

=head2 :Option

    sub init :Action
        :Argument(name, "workplace name")
        :Option("v|verbose=i", "verbosity level")
    { ... some code ... }

    Declares that action has getopt-style option

=cut

sub Option :ATTR(CODE, BEGIN) {
    my ($package, $symbol, $referent, $attr, $data) = @_;
    my $method = *{$symbol}{NAME};
    my $info = _get_action_by_method($method);

    my ($opt, $descr) = (ref $data ? @$data : $data);
    push @{$info->{options}}, $opt;
    $info->{opt_descr}->{$opt} = $descr  if $descr;
    return;
}


=head1 FUNCTIONS

=head2 run

Process command-line options and execute action

=cut

sub run {
    my ($self, $action_name) = @_;

    my $action = shift @ARGV || 'help';
    my $action_info = _get_action_by_name($action);

    my %arg;
    if ( $action_info->{options} ) {
        GetOptions(
            map {( $_ => \$arg{_get_option_key($_)} )}
            @{$action_info->{options}}
        ) or croak "Bad options, stop";
    }

    for my $arg_name ( @{$action_info->{req_args} || []} ) {
        my $arg_value = shift @ARGV;
        croak "Required argument <$arg_name> is not defined"  if !defined $arg_value;
        $arg{$arg_name} = $arg_value;
    }
    
    for my $arg_name ( @{$action_info->{opt_args} || []} ) {
        my $arg_value = shift @ARGV;
        last  if !defined $arg_value;
        $arg{$arg_name} = $arg_value;
    }

    return $action_info->{sub}->( map {($_ => $arg{$_})} grep {defined $arg{$_}} keys %arg );
}


=head1 BUILT-IN ACTIONS

=head2 help

Assemble and show usage info.

=cut

sub print_usage_info
    :Action(help, '-h', '--help')
    :Description("Show basic usage info")
    :OptionalArgument(action)
{
    my %opt = @_;

    my $action = $opt{action};
    if ( $action ) {
        my $action_info = _get_action_by_name($action)
            or croak "Unknown action <$action>";

        say "Usage:";
        say "  $0 $action " . _join_arg_help_list($action_info->{req_args}, $action_info->{opt_args});
        say "\n$action_info->{description}"  if $action_info->{description};
        
        my @arg_table =
            grep {$_->[1]}
            map {[$_ => $action_info->{arg_descr}->{$_}]}
            map {@{$action_info->{$_} || []}}
            qw/ req_args opt_args /;

        if ( @arg_table ) {
            say "\nArguments:";
            say _format_table(\@arg_table, "  %s  -  %-s");
        }
        
        my @opt_table =
            grep {$_->[1]}
            map {[_get_option_key($_) => $action_info->{opt_descr}->{$_}]}
            @{$action_info->{options} || []};

        if ( @opt_table ) {
            say "\nOptions:";
            say _format_table(\@opt_table, "  --%-s   %-s");
        }

        if ( my $pod = `podselect -sections /$action_info->{method} $action_info->{source} | pod2text` ) {
            # remove first line: we don't need header
            $pod =~ s/^[^\n]+//xms;
            say $pod;
        }
    }
    # main usage
    else {
        say "Usage:";
        say "  $0 <action> [<args>] [<options>]";

        if ( my $pod = `podselect -sections DESCRIPTION/!.+ $0 | pod2text` ) {
            # remove first line: we don't need header
            $pod =~ s/^[^\n]+//xms;
            print $pod;
        }

        say "\nActions:";

        my @table;
        for my $action_info ( @{ _get_actions_list() } ) {
#            next if !$action_info->{description};
            push @table, [
                $action_info->{action},
                _join_arg_help_list($action_info->{req_args}, $action_info->{opt_args}),
                $action_info->{description},
            ];
        }
        say _format_table(\@table, "  %s %-s  -  %-s");
    }

    return;
}


sub _join_arg_help_list {
    my ($req_args, $opt_args) = @_;
    return  join ( q{ },
        ( map {"<$_>"} @{ $req_args || [] } ),
        ( map {"[<$_>]"} @{ $opt_args || [] } ),
    );
}


sub _get_option_key {
    my ($getopt_key) = @_;
    my ($key) = $getopt_key =~ /^([\w\-]+)/xms;
    return $key;
}


sub _format_table {
    my ($table, $format) = @_;
    
    my @maxlens;
    for my $row (@$table) {
        for my $i (0 .. $#$row) {
            next if $maxlens[$i] && length $row->[$i] <= $maxlens[$i];
            $maxlens[$i] = length $row->[$i];
        }
    }

    $format //= join q{ }, ("%-s") x scalar @maxlens;
    $format =~ s/(%-?)/$1 . shift @maxlens/gexms;

    return join qq{\n}, map {sprintf $format, @$_} @$table;
}


=head2 LIST

Show list of supported actions.

=cut

sub list_actions
    :Action(LIST)
    :Hidden
    :Description('Show list of available actions')
    :Option(full, 'show hidden actions also')
{
    my %opt = @_;

    my $actions = _get_action_names($opt{full});
    say join qq{\n}, @$actions;
    return;
}



sub import
{
    my $class = shift;
    my $inheritor = caller(0);
    my ($run) = @_;

    {
        no strict 'refs';
        push @{"$inheritor\::ISA"}, $class;
        *{"$inheritor\::$run"} = \&run  if $run;
    };

    return;
}


1;

