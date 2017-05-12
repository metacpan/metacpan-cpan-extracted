package TestCGI::upload1;

use strict;
use warnings FATAL => 'all';

use Apache2::RequestRec;
use Apache2::RequestIO;
use Apache2::Request ();
use CGI::Apache2::Wrapper;
use Apache2::Const -compile => qw(OK);
use File::Spec;
require File::Basename;

sub handler {
    my $r = shift;
    my $cgi = CGI::Apache2::Wrapper->new($r);
    my $cgi_fh = $cgi->upload("filename");
    my $ref = ref($cgi_fh);
    my $temp_dir = File::Spec->tmpdir;

    my $has_md5  = $cgi->param('has_md5');
    require Digest::MD5 if $has_md5;
    my $info = $cgi->uploadInfo($cgi_fh);
    my $type = $info->{type};
    my $basename = File::Basename::basename($info->{filename});
    my ($data);

    binmode $cgi_fh;
    read $cgi_fh, $data, $info->{size};
    close $cgi_fh;

    my $temp_file = File::Spec->catfile($temp_dir, $basename);
    unlink $temp_file if -f $temp_file;
    open my $wfh, ">", $temp_file or die "Can't open $temp_file: $!";
    binmode $wfh;
    print $wfh $data;
    close $wfh;
    my $cs = $has_md5 ? cs($temp_file) : 0;

    $r->content_type('text/plain');
    my $size = -s $temp_file;
    my $response = qq{name=filename;ref=$ref;type=$type;size=$size;filename=$basename;md5=$cs};
    $r->print($response);
    unlink $temp_file if -f $temp_file;
    return Apache2::Const::OK;
}

sub cs {
    my $file = shift;
    open my $fh, '<', $file or die qq{Cannot open "$file": $!};
    binmode $fh;
    my $md5 = Digest::MD5->new->addfile($fh)->hexdigest;
    close $fh;
    return $md5;
}

1;
__END__
