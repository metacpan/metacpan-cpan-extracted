package Couchbase::BucketConfig;
use strict;
use warnings;
use Couchbase::_GlueConstants;

my %SVC2STR = (
    SVCTYPE_MGMT+0 => "management",
    SVCTYPE_VIEWS+0 => "views",
    SVCTYPE_DATA+0 => "data"
);

my %MODE2STR = (
    SVCMODE_PLAIN+0 => "plain",
    SVCMODE_SSL+0 => "ssl"
);

sub nodes {
    my $self = shift;
    my @ret;
    for (my $ii = 0; $ii < $self->nservers; ++$ii) {
        my $srvhash = {};
        push @ret, $srvhash;
        while (my ($i_type,$s_type) = each %MODE2STR) {
            my $svchash = $srvhash->{$s_type} = {};
            while (my ($i_svc,$s_svc) = each %SVC2STR) {
                $svchash->{$s_svc} = $self->_gethostport($ii, $i_svc, $i_type);
            }
            $svchash->{capi_url_base} = $self->_getcapi($ii, $i_type);
        }
    }
    return \@ret;
}
