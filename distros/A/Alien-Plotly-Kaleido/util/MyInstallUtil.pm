package MyInstallUtil;

use strict;
use warnings;

sub detect_kaleido_version {
    require File::Which;
    require IPC::Run;
    require JSON;

    my $kaleido = File::Which::which('kaleido');
    if ($kaleido) {
        my $decode_json_safe = sub {
            my ($out) = @_;
            my $data;
            eval { $data = JSON::decode_json($out); };
            $@ = '' if ($@);
            return $data;
        };

        my @cmd = ( $kaleido, 'plotly', '--disable-gpu', '--no-sandbox' );
        eval {
            require Chart::Plotly;
            my $plotlyjs =
              File::ShareDir::dist_file( 'Chart-Plotly',
                'plotly.js/plotly.min.js' );
              if ( -r $plotlyjs ) {
                push @cmd, "--plotlyjs=$plotlyjs";
            }
        };
        my $h;
        my $data;
        eval {
            my ( $in, $out, $err );
            $h = IPC::Run::start( \@cmd, \$in, \$out, \$err,
                my $t = IPC::Run::timer(30) );
            while ( not $data and not $t->is_expired ) {
                $h->pump;
                $data = $decode_json_safe->($out);
            }
            $h->finish;
        };
        if ($@) {
            warn $@;
            $h->kill_kill;
        }
        if ( $data and exists $data->{version} ) {
            return $data->{version};
        }
    }

    die "Failed to detect kaleido version";
}

1;
