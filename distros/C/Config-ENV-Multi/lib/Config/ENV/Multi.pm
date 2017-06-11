package Config::ENV::Multi;
use 5.008001;
use strict;
use warnings;
use Carp qw/croak/;

our $VERSION = "0.04";

use constant DELIMITER => '@#%@#';

sub import {
    my $class   = shift;
    my $package = caller(0);

    no strict 'refs';
    if (__PACKAGE__ eq $class) {
        my $envs = shift;
        my %opts    = @_;
        #
        # rule => '{ENV}_{REGION}',
        # any => '*',
        # unset => '&';
        #

        push @{"$package\::ISA"}, __PACKAGE__;

        for my $method (qw/common config any unset parent load/) {
            *{"$package\::$method"} = \&{__PACKAGE__ . "::" . $method}
        }

        my %wildcard = (
            any   => '*',
            unset => '!',
        );
        $wildcard{any}   = $opts{any}   if $opts{any};
        $wildcard{unset} = $opts{unset} if $opts{unset};

        $envs = [$envs] unless ref $envs;
        my $mode = $opts{rule} ? 'rule': 'env';

        no warnings 'once';
        ${"$package\::data"} = +{
            configs  => {},
            mode     => $mode, # env or rule
            envs     => $envs,
            rule     => $opts{rule},
            wildcard => \%wildcard,
            cache    => {},
            local    => [],
            export   => $opts{export},
        };
    } else {
        my %opts    = @_;
        my $data = _data($class);
        if (my $export = $opts{export} || $data->{export}) {
           *{"$package\::$export"} = sub () { $class };
        }
    }
}

# copy from Config::ENV
sub load ($) { ## no critic
    my $filename = shift;
    my $hash = do "$filename";

    croak $@ if $@;
    croak $^E unless defined $hash;
    unless (ref($hash) eq 'HASH') {
        croak "$filename does not return HashRef.";
    }

    wantarray ? %$hash : $hash;
}

sub parent ($) { ## no critic
    my $package = caller(0);
    my $e_or_r = shift;

    my $target;
    my $data = _data($package);
    if ($data->{mode} eq 'env') {
        $target = __envs2key($e_or_r);
    } else {
        $target = __envs2key(__clip_rule($data->{rule}, $e_or_r));
    }
    %{ $data->{configs}{$target}->as_hashref || {} };
}

sub any {
    my $package = caller(0);
    _data($package)->{wildcard}{any};
}

sub unset {
    my $package = caller(0);
    _data($package)->{wildcard}{unset};
}

# {ENV}_{REGION}
# => ['ENV', 'REGION]
sub __parse_rule {
    my $rule = shift;
    return [
        grep { defined && length }
        map {
            /^\{(.+?)\}$/ ? $1 : undef
        }
        grep { defined && length }
        split /(\{.+?\})/, $rule
    ];
}

# {ENV}_{REGION} + 'prod_jp'
# => ['prod', 'jp']
sub __clip_rule {
    my ($template, $rule) = @_;
    my $spliter = [
        grep { defined && length }
        map {
            /^\{(.+?)\}$/ ? undef : $_
        }
        grep { defined && length }
        split /(\{.+?\})/, $template
    ];
    my $pattern = '(.*)' . ( join '(.*)', @{$spliter} ) . '(.*)';
    my @clip = ( $rule =~ /$pattern/g );
    return \@clip;
}

sub _data {
    my $package = shift;
    no strict 'refs';
    no warnings 'once';
    ${"$package\::data"};
}

sub common {
    my $package = caller(0);
    my $hash = shift;
    my $data = _data($package);
    my $envs = $data->{envs};
    $envs = [$envs] unless ref $envs;
    my $any  = $data->{wildcard}{any};
    _config_env($package, [ map { "$any" } @{$envs} ], $hash);
}

sub config {
    my $package = caller(0);
    if (_data($package)->{mode} eq 'env') {
        return _config_env($package, @_);
    } else {
        return _config_rule($package, @_);
    }
}

sub _config_env {
    my ($package, $envs, $hash) = @_;

    my $data = _data($package);
    my $wildcard = $data->{wildcard};
    $envs = [ $envs ] unless ref $envs;

    $data->{configs}{__envs2key($envs)} = Config::ENV::Multi::ConfigInstance->new(
        order    => 0 + ( grep { $_ ne $wildcard->{any} } @$envs ),
        pattern  => $envs,
        hash     => $hash,
        wildcard => $wildcard,
    );
}

sub _config_rule {
    my ($package, $rule, $hash) = @_;
    _config_env($package, __clip_rule(_data($package)->{rule}, $rule), $hash);
}

sub current {
    my $package = shift;
    my $data = _data($package);

    my $target_env = [ map { $ENV{$_} } @{ $data->{envs} } ];

    my $vals = $data->{cache}->{__envs2key($target_env)} ||= +{
        %{ _match($package, $target_env) }
    };
}

sub local :method {
    my ($package, %hash) = @_;
    not defined wantarray and croak "local returns guard object; Can't use in void context.";

    my $data = _data($package);
    push @{ $data->{local} }, \%hash;
    %{ $data->{cache} } = ();

    bless sub {
        @{ $data->{local} } = grep { $_ != \%hash } @{ $data->{local} };
        %{ $data->{cache} } = ();
    }, 'Config::ENV::Multi::Local';
}

sub param {
    my ($package, $name) = @_;
    $package->current->{$name};
}

sub __envs2key {
    my $v = shift;
    $v = [$v] unless ref $v;
    join DELIMITER(), map { defined $_ ? $_ : '' } @{$v};
}

sub __key2envs {
    my $f = shift;
    [split DELIMITER(), $f];
}

sub _match {
    my ( $package, $target_envs ) = @_;

    my $data = _data($package);

    return +{
        (map  { %{ $_->as_hashref } }
         grep { $_->match($target_envs) }
         sort { $a->{order} - $b->{order} }
         values %{ $data->{configs} }),
        (map { %$_ } @{ $data->{local} })
    };
}

1;

package Config::ENV::Multi::ConfigInstance;
use strict;
use warnings;

use List::MoreUtils qw/ all pairwise /;

sub new {
    my ( $class, %args ) = @_;

    bless +{
        order    => $args{order},
        pattern  => $args{pattern},
        hash     => $args{hash},
        wildcard => $args{wildcard},
    }, $class;
}

sub match {
    my ( $self, $target ) = @_;

    return all { $_ } pairwise {
        $a eq $self->{wildcard}{any}   ?           1 :
        $a eq $self->{wildcard}{unset} ? !defined $b :
                                          defined $b && $b eq $a;
    } @{ $self->{pattern} }, @{ $target };
}

sub as_hashref { $_[0]->{hash} }

package # to hide from pause
    Config::ENV::Multi::Local;

sub DESTROY {
    my $self = shift;
    $self->();
}

1;

__END__

=encoding utf-8

=head1 NAME

Config::ENV::Multi - Config::ENV supported Multi ENV

=head1 SYNOPSIS

    package Config;
    use Config::ENV::Multi [qw/ENV REGION/], any => ':any:', unset => ':unset:';

    common {
        # alias of [qw/:any: :any:/]
        # alias of [any, any]
        cnf => 'my.cnf',
    };

    config [qw/dev :any:/] => sub {
        debug => 1,
        db    => 'localhost',
    };

    config [qw/prod jp/] => sub {
        db    => 'jp.localhost',
    };

    config [qw/prod us/] => sub {
        db    => 'us.localhost',
    };

    Config->current;
    # $ENV{ENV}=dev, $ENV{REGION}=jp
    # {
    #   cnf    => 'my.cnf',
    #   debug  => 1,
    #   db     => 'localhost',
    # }

=head1 DESCRIPTION

supported multi environment L<Config::ENV>.

=head1 SEE ALSO

L<Config::ENV>

=head1 LICENSE

Copyright (C) Hiroyoshi Houchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hiroyoshi Houchi E<lt>git@hixi-hyi.comE<gt>

=cut

