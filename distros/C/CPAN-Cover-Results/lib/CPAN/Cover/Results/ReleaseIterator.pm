package CPAN::Cover::Results::ReleaseIterator;
$CPAN::Cover::Results::ReleaseIterator::VERSION = '0.03';
use Moo;
use autodie;
use JSON qw/ decode_json /;
use Carp;

use CPAN::Cover::Results::Release;

has 'results'       => ( is => 'ro'   );
has '_results_data' => ( is => 'lazy' );
has '_keys'         => ( is => 'lazy' );

sub _build__results_data
{
    my $self = shift;
    my $fh   = $self->results->open_file();
    local $/;

    my $json_text = <$fh>;
    close($fh);
    return decode_json($json_text);
}

sub _build__keys
{
    my $self            = shift;
    my $results_ref     = $self->_results_data;
    my $keypair_listref = [];

    foreach my $distname (sort { lc($a) cmp lc($b) } keys %$results_ref) {
        foreach my $version (sort keys %{ $results_ref->{$distname} }) {
            next unless exists($results_ref->{$distname}{$version}{coverage}{total})
                     && int(keys %{ $results_ref->{$distname}{$version}{coverage}{total} }) > 0;
            push(@$keypair_listref, [$distname, $version]);
        }
    }

    return $keypair_listref;
}

sub next
{
    my $self            = shift;
    my $data_ref        = $self->_results_data;
    my $keypair_listref = $self->_keys;

    return undef unless @$keypair_listref > 0;

    my $keypair              = shift @$keypair_listref;
    my ($distname, $version) = @$keypair;
    my $result_record        = {
                                  distname => $distname,
                                  version  => $version,
                                  %{ $data_ref->{$distname}->{$version}->{coverage}->{total} },
                               };

    return CPAN::Cover::Results::Release->new($result_record);
}

1;

