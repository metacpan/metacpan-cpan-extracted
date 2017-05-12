
use strict;
use warnings;
package App::HTTP_Proxy_IMP::IMP::FakeResponse;
use base 'Net::IMP::HTTP::Request';
use fields qw(root file response);

use Net::IMP;
use Net::IMP::Debug;
use Carp;
use Digest::MD5;

sub RTYPES { ( IMP_PASS,IMP_REPLACE,IMP_DENY,IMP_ACCTFIELD ) }

sub new_factory {
    my ($class,%args) = @_;
    my $dir = $args{root} or croak("no root directory given");
    -d $dir && -r _ && -x _ or croak("cannot use base dir $dir: $!");
    my $obj = $class->SUPER::new_factory(%args);
    $obj->{root} = $dir;
    return $obj;
}

sub validate_cfg {
    my ($class,%args) = @_;
    my $dir = delete $args{root};
    delete $args{ignore_parameters};
    my @err = $class->SUPER::validate_cfg(%args);
    if ( ! $dir ) {
	push @err, "no 'root' given";
    } elsif ( ! -d $dir || ! -r _ || ! -x _ ) {
	push @err, "cannot access root dir $dir";
    }
    return @err;
}

sub request_hdr {
    my ($self,$hdr) = @_;

    my ($method,$proto,$host,$path) = $hdr =~m{\A([A-Z]+) +(?:(\w+)://([^/]+))?(\S+)};
    $host = $1 if $hdr =~m{\nHost: *(\S+)}i;
    if ( ! $host ) {
	$self->run_callback([IMP_DENY,0,'cannot determine host']);
	return;
    }
    $proto ||= 'http';
    $host = lc($host);
    my $port =
        $host=~s{^(?:\[(\w._\-:)+\]|(\w._\-))(?::(\d+))?$}{ $1 || $2 }e ?
        $3:80;

    my $dir = $self->{factory_args}{root}."/$host:$port";
    goto IGNORE if ! -d $dir;

    my $uri = "$proto://$host:$port$path";
    my $qstring = $path =~s{\?(.+)}{} ? $1 : undef;
    # collect information to determine filename
    my %file = (
	uri => $uri,
        dir => $dir,
        method => $method,
        md5path => Digest::MD5->new->add($path)->hexdigest,
        md5data => undef,
    );

    my $fname = "$dir/".lc($method)."-".$file{md5path};
    goto TRY_FNAME if $self->{factory_args}{ignore_parameters};

    ( $file{md5data} = Digest::MD5->new )->add("\000$qstring\001")
        if defined $qstring;
    if ( $method ~~ [ 'GET','HEAD' ] ) {
	$fname .= "-".$file{md5data}->hexdigest if $file{md5data};
	goto TRY_FNAME;
    }

    # ignore if there will not be a matching filename, no matter
    # what md5data will be
    goto IGNORE if ! -f $fname and ! glob("$fname-*");

    # don't pass yet, continue in request body
    $file{rqhdr} = $hdr; 
    $self->{file} = \%file;
    return; 

    TRY_FNAME:
    if ( $self->{response} = _extract_response($fname)) {
	$hdr =~s{(\A\w+\s+)}{$1internal://};
	debug("hijack http://$host:$port$path");
	$self->run_callback( 
	    [ IMP_ACCTFIELD,'orig_uri',$uri ],
	    [ IMP_REPLACE,0,$self->offset(0),$hdr ],
	    [ IMP_PASS,0,IMP_MAXOFFSET ]
	);
	return;
    }

    IGNORE:
    $self->run_callback( 
	[ IMP_PASS,0,IMP_MAXOFFSET ],
	[ IMP_PASS,1,IMP_MAXOFFSET ],
    );
}

sub request_body {
    my ($self,$data) = @_;
    my $f = $self->{file} or return;
    my $md = $f->{md5data};
    if ( $data ne '' ) {
	$md ||= $f->{md5data} = Digest::MD5->new;
        $md->add($data);
        return;
    }

    # eof of request body - determine final filename
    $self->{file} = undef;
    my $fname = $f->{dir}.'/'.join('-',
	lc($f->{method}),
	$f->{md5path},
	$f->{md5data} ? ($f->{md5data}->hexdigest):()
    );

    # setup response if file is found
    if ( $self->{response} = _extract_response($fname)) {
	( my $hdr = $f->{rqhdr})=~s{(\A\w+\s+)}{$1internal://};
	debug("hijack $f->{uri}");
	$self->run_callback( 
	    [ IMP_ACCTFIELD,'orig_uri',$f->{uri} ],
	    [ IMP_REPLACE,0,length($f->{rqhdr}),$hdr ],
	    [ IMP_PASS,0,IMP_MAXOFFSET ]
	);
	return;
    }

    # otherwise pass everything through
    $self->run_callback( 
	[ IMP_PASS,0,IMP_MAXOFFSET ],
	[ IMP_PASS,1,IMP_MAXOFFSET ],
    );
}


sub response_hdr {
    my ($self,$hdr) = @_;
    my $rphdr = $self->{response} && $self->{response}[0] or return;
    $rphdr =~s{\r?\n}{\r\n}g;
    my $clen = length($self->{response}[1]);
    $rphdr =~s{(\nContent-length:[ \t]*)\d+}{$1$clen} or 
	$rphdr =~s{\n}{\nContent-length: $clen\r\n};
    warn "XXXX offset=".$self->offset(1)." len=".length($hdr);
    $self->run_callback([ IMP_REPLACE,1,$self->offset(1),$rphdr ]);
}

sub response_body {
    my ($self,$data) = @_;
    my $rp = $self->{response} or return;
    $self->{response} = undef;
    warn "XXXX offset=".$self->offset(1)." len=".length($data);
    $self->run_callback(
	[ IMP_REPLACE,1,$self->offset(1),$rp->[1] ],
	[ IMP_PASS,1,IMP_MAXOFFSET ],
    );
}

sub any_data {
    my $self = shift;
    # ignore
    $self->{file} or return;
    $self->{file} = undef;
    $self->run_callback(
	[ IMP_PASS,0,IMP_MAXOFFSET ],
	[ IMP_PASS,1,IMP_MAXOFFSET ],
    );
}

sub _extract_response {
    my $fname = shift;
    open( my $fh,'<',$fname) or return;
    my $data = do { local $/; <$fh> };
    if ( $data =~s{\A(HTTP/1\.[01] .*?(\r?\n)\2)}{}s ) {
	# only response header + body
	return [ $1,$data ];
    } else {
	my @size = unpack("NNNN",substr($data,-16));
	if ( $size[0]+$size[1]+$size[2]+$size[3] + 16 == length($data)) {
	    # format used by Net::IMP::HTTP::SaveResponse
	    my $rq = $size[0]+$size[1]; # skip request
	    return [
		substr($data,$rq,$size[2]),          # response header
		substr($data,$rq+$size[2],$size[3])  # response body
	    ],
	}
    }
    debug("unknown format in $fname");
    return;
}

1;

__END__

=head1 NAME 

App::HTTP_Proxy_IMP::IMP::FakeResponse - return alternativ response header and
body for specific URIs

=head1 SYNOPSIS

  # listen on 127.0.0.1:8000 
  # to hijack google analytics put alternative response into 
  # myroot/www.google-analytics.com/ga.js or
  # myroot/www.google-analytics.com:80/ga.js or

  $ perl bin/imp_http_proxy --filter FakeResponse=root=myroot 127.0.0.1:8000


=head1 DESCRIPTION

This module is used to hijack specific URIs and return a different response.
It works by replacing the origin target in the request header with
internal://imp, which causes L<App::IMP_HTTP_Proxy_IMP> to inject a dummy HTTP
response header and body into the data stream, instead of contacting the
original server.
This dummy response is than replaced with the alternative response.

The format and file name for the alternative responses is the same as in 
L<Net::IMP::HTTP::SaveResponse>, see there for details.

C<new_analyzer> has the following arguments:

=over 4

=item root

Specifies the base directory, where the alternative responses are
located. 

=item ignore_parameters

Ignore query string or post data when computing the file name.

=back

=head1 AUTHOR

Steffen Ullrich <sullr@cpan.org>
