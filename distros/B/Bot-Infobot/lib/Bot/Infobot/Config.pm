package Bot::Infobot::Config;

use strict;
use vars qw(@EXPORT_OK);
use Exporter;
use base qw(Exporter);

use Config::Tiny;


@EXPORT_OK = qw(parse_config save_config);

=head1 NAME

Bot::Infobot::Config - parse Bot::Infobot config files

=head1 SYNOPSIS

        use Bot::Infobot::Config qw(parse_config);

        my %config = parse_config('infobot.conf');


=head1 METHODS

=head2 parse_config <config file>

Returns a hash of config values.

Sub parts are in sub hashes. For example

        foo = bar;

        [ Sub ]
        quirka = fleeg

would be converted to

        (
           'foo' => 'bar',
           'sub' => {
                        'quirka' => 'fleeg',
                    }
        )

=cut

sub parse_config {
        my $file  = shift || die "You must pass a file";

        # read the config, if it exists
        my $config = Config::Tiny->read($file);

        # read all the root config values in, splitting where necessary
        my %conf;
        foreach my $key (keys %{$config->{_}}) {
                my $val = $config->{_}->{$key};
                $conf{$key} = $val;
        }
        delete $config->{_};
        while (my ($key,$val) = each %{$config}) {
          $key =~ s!(^\s*|\s*$)!!g;       
              if ($key eq 'Store') {
                        $conf{'store'} = $val;
                } else {
                        $conf{$key} = $val;
                }
        }

        return %conf;
}


=head2 save_config <file> <hash of values>

Save the config back out again.

=cut

sub save_config {
        my $file = shift || die "You must pass a file";
        my $conf = (-f $file)? Config::Tiny->read($file) : Config::Tiny->new();
        my %vars = @_;


        while (my($key,$val) = each %vars) {
                $val = join " ", @$val if ref $val eq 'ARRAY';
                if (ref $val eq 'HASH') {
                        $key = 'Store' if $key eq 'store';
                        $conf->{" $key "} = $val;
                        next;
                }
                $conf->{_}->{$key} = $val;

        }

        $conf->write($file);
}

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2005, Simon Wistow

Distributed under the same terms as Perl itself.

=cut

1;

