use 5.008;
use strict;
use warnings;
package BenchmarkAnything::Config;
BEGIN {
  $BenchmarkAnything::Config::AUTHORITY = 'cpan:SCHWIGON';
}
# ABSTRACT: Read BenchmarkAnything configfile
$BenchmarkAnything::Config::VERSION = '0.003';

sub new
{
        my $class = shift;
        my $self  = bless { @_ }, $class;
        $self->_read_config;
        return $self;
}


sub _read_config
{
        my ($self) = @_;

        require File::HomeDir;
        require YAML::Any;

        # don't look into user's homedir if we are running tests
        my $default_cfgfile = $ENV{HARNESS_ACTIVE} ? "t/benchmarkanything.cfg" : $ENV{BENCHMARKANYTHING_CONFIGFILE} || File::HomeDir->my_home . "/.benchmarkanything/default.cfg";

        # read file
        eval {
                $self->{cfgfile} = $self->{cfgfile} || $default_cfgfile;
                my $cfg_yaml;
                open (my $CFG, "<", $self->{cfgfile}) or die "Can't read: ".$self->{cfgfile}."\n";
                {
                        local $/;
                        $cfg_yaml = <$CFG>;
                }
                my $config = YAML::Any::Load($cfg_yaml);
                $self->{benchmarkanything} = $config->{benchmarkanything};
        };
        if ($@)
        {
                die "benchmarkanything: error loading configfile: $@\n";
        }

        # defaults
        $self->{benchmarkanything}{backend} ||= 'local';

        return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BenchmarkAnything::Config - Read BenchmarkAnything configfile

=head2 new

Instantiate a new object.

=over 4

=item * cfgfile

Path to config file. If not provided it uses env variable
C<BENCHMARKANYTHING_CONFIGFILE> or C<$home/.benchmarkanything.cfg>.

=back

=head2 _read_config

Internal function.

Reads the config file; either from given file name, or env variable
C<BENCHMARKANYTHING_CONFIGFILE> or C<$HOME/.benchmarkanything.cfg>.

Returns the object to allow chained method calls.

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
