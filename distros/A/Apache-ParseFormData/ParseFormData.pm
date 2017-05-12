#############################################################################
#
# Apache::ParseFormData
# Last Modification: Thu Oct 23 11:44:58 WEST 2003
#
# Copyright (c) 2003 Henrique Dias <hdias@aesbuc.pt>. All rights reserved.
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
##############################################################################
package Apache::ParseFormData;

use strict;
use Apache::Log;
use Apache::Const -compile => qw(OK M_POST M_GET FORBIDDEN HTTP_REQUEST_ENTITY_TOO_LARGE);
use Apache::RequestIO ();
use APR::Table;
use IO::File;
use POSIX qw(tmpnam);
require Exporter;
our @ISA = qw(Exporter Apache::RequestRec);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT = qw();
our $VERSION = '0.09';
require 5;

use constant NELTS => 10;
use constant BUFFLENGTH => 1024;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = shift;
	my %args = (
		temp_dir        => "/tmp",
		disable_uploads => 0,
		post_max        => 0,
		@_,
	);
	my $table = APR::Table::make($self->pool, NELTS);
	$self->pnotes('apr_req' => $table);
	bless ($self, $class);

	if(my $data = $self->headers_in->get('cookie')) {
		&_parse_query($self, $data, " *; *");
	}
	if($self->method_number == Apache::M_POST) {
		$self->pnotes('apr_req_result' => &parse_content($self, \%args));
	} elsif($self->method_number == Apache::M_GET) {
		my $data = $self->args();
		&_parse_query($self, $data) if($data);
		$self->pnotes('apr_req_result' => Apache::OK);
	}
	return($self);
}

sub DESTROY {  
	my $self = shift;
	for my $v (values(%{$self->pnotes('upload')})) {
		my $path = $v->[1];
		unlink($path) if(-e $path);
	}
}

sub parse_result { $_[0]->pnotes('apr_req_result') }

sub parms { $_[0]->pnotes('apr_req') }

sub _parse_query {
	my $r = shift;
	my $query_string = shift;
	my $re = shift || "&";

	my %hash = ();
	for(split(/$re/, $query_string)) {
		my ($n, $v) = split(/=/);
		defined($v) or $v = "";
		&decode_chars($n);
		&decode_chars($v);
		push(@{$hash{$n}}, $v);
	}
	$r->param(%hash);
	return();
}

sub decode_chars {
	$_[0] =~ tr/+/ /;
	$_[0] =~ s/%([\dA-Fa-f][\dA-Fa-f])/pack("C", hex($1))/egi;
}

sub set_cookie {
	my $self = shift;
	my $args = {
		name    => "",
		value   => "",
		path    => "/",
		expires => "",
		secure  => 0,
		domain  => "",
		@_,
	};
	$args->{'name'} or return();
	my @a = (
		join("=", $args->{'name'}, $args->{'value'}),
		join("=", "path", $args->{'path'}),
	);
	push(@a, join("=", "expires", &cookie_expire($args->{'expires'}))) if($args->{'expires'});
	push(@a, join("=", "secure", $args->{'secure'})) if($args->{'secure'});
	push(@a, join("=", "domain", $args->{'domain'})) if($args->{'domain'});
	$self->headers_out->{'Set-Cookie'} = join(";", @a);
	$self->param($args->{'name'} => $args->{'value'});
	return();
}

sub cookie_expire {
	my $time = shift;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday) = localtime($time);
	my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	my @weekday = qw(Sun Mon Tue Wed Thu Fri Sat);
	return sprintf("%3s, %02d-%3s-%04d %02d:%02d:%02d GMT", $weekday[$wday], $mday, $months[$mon], $year+1900, $hour, $min, $sec);
}

sub upload {
	my $self = shift;
	my $name = shift || "";
	return($name ? @{$self->pnotes('upload')->{$name}} : keys(%{$self->pnotes('upload')}));
}

sub parse_content {
	my $r = shift;
	my $args = shift;

	my $buf = "";
	$r->setup_client_block;
	$r->should_client_block or return '';
	my $ct = $r->headers_in->get('content-type');

	if($args->{'disable_uploads'} && index($ct, "multipart/form-data") > -1) {
		my $error_str = "[Apache::ParseFormData] file upload forbidden";
		$r->notes->set("error-notes" => $error_str);
		$r->log_error($error_str);
		return(Apache::FORBIDDEN);
	}
	my $rm = $r->remaining;
	if($args->{'post_max'} && ($rm > $args->{'post_max'})) {
		my $pm = $args->{'post_max'};
		my $error_str = "[Apache::ParseFormData] entity too large ($rm, max=$pm)";
		$r->notes->set("error-notes" => $error_str);
		$r->log_error($error_str);
		return(Apache::HTTP_REQUEST_ENTITY_TOO_LARGE);
	}
	if($ct =~ /^multipart\/form-data; boundary=(.+)$/) {
		my $boundary = $1;
		my $lenbdr = length("--$boundary");
		$r->get_client_block($buf, $lenbdr+2);
		$buf = substr($buf, $lenbdr);
		$buf =~ s/[\n\r]+//;
		my $iter = -1;
		my @data = ();
		&multipart_data($r, $args, \@data, $boundary, BUFFLENGTH, 1, $buf, $iter);
		my %uploads = ();
		for(@data) {
			if(exists($_->{'headers'}->{'content-disposition'})) {
				my @a = split(/ *; */, $_->{'headers'}->{'content-disposition'});
				if(shift(@a) eq "form-data") {
					if(scalar(@a) == 1) {
						my ($key) = ($a[0] =~ /name=\"([^\"]+)\"/);
						$r->param($key => $_->{'values'} || "");
					} else {
						(ref($_->{'values'}) eq "ARRAY") or next;
						my ($fh, $path) = @{$_->{'values'}};
						seek($fh, 0, 0);
						my %hash = (
							filename => "",
							type     => exists($_->{'headers'}->{'content-type'}) ? $_->{'headers'}->{'content-type'} : "",
							size     => ($fh->stat())[7],
						);
						my $param = "";
						for(@a) {
							my ($name, $value) = (/([^=]+)=\"([^\"]+)\"/);
							if($name eq "name") {
								$uploads{$value} = [$fh, $path];
								$param = $value;
							} else {
								$hash{$name} = $value;
							}
						}
						$r->param($param => \%hash);
					}
				}
			}
		}
		$r->pnotes('upload' => \%uploads);
	} else {
		my $len = $r->headers_in->get('content-length');
		$r->get_client_block($buf, $len);
		&_parse_query($r, $buf) if($buf);
	}
	return(Apache::OK);
}

sub extract_headers {
	my $raw = shift;
	my %hash = ();
	for(split(/\r?\n/, $raw)) {
		s/[\r\n]+$//;
		$_ or next;
		my ($h, $v) = split(/ *: */, $_, 2);
		$hash{lc($h)} = $v;
	}
	$_[0] = \%hash;
	return(exists($hash{'content-type'}));
}

sub output_data {
	my $dest = shift;
	my $data = shift;

	if(ref($dest->{values}) eq "ARRAY") {
		my $fh = $dest->{values}->[0];
		print $fh $data;
	} else { $dest->{values} .= $data; }
}

sub new_tmp_file {
	my $temp_dir = shift;
	my $data = shift;

	my $path = "";
	my $fh;
	my $i = 0;
	do {
		$i < 3 or last;
		my $name = tmpnam(); 
		$name = (split("/", $name))[-1];
		$path = join("/", $temp_dir, $name);
		$i++;
	} until($fh = IO::File->new($path, O_RDWR|O_CREAT|O_EXCL));
	defined($fh) or return("Couldn't create temporary file: $path");
	binmode($fh);
	$fh->autoflush(1);
	$data->{values} = [$fh, $path];
	return();
}

sub multipart_data {
	my $r = shift;
	my $args = shift;
	my $data = shift;
	my $boundary = shift;
	my $len = shift;
	my $h = shift;
	my $buff = shift;

	my ($part, $content) = ($buff, "");
	while($r->get_client_block($buff, $len)) {
		$part .= $buff;
		if($h) {
			if($part =~ /\r?\n\r?\n/) {
				my ($left, $right) = ($`, $');
				$left =~ s/[\r\n]+$//;
				$_[0]++;
				push(@{$data}, {values => "", headers => {}});
				if(&extract_headers($left, $data->[$_[0]]->{'headers'})) {
					if(my $error = &new_tmp_file($args->{'temp_dir'}, $data->[$_[0]])) { $r->log->warn($error), next; }
				}
				$part = $content = $right;
				$h = 0;
			} else { next; }
		}
		if($part =~ /\r?\n--$boundary\r?\n/) {
			my ($left, $right) = ($`, $');
			&output_data($data->[$_[0]], $left) if($left);
			&multipart_data($r, $args, $data, $boundary, $len, 1, $right, $_[0]);
			$part = "";
		}
		if($part) {
			$content = substr($part, 0, int($len/2));
			&output_data($data->[$_[0]], $content) if($content);
			$part = substr($part, int($len/2));
		}
	}
	if($h && $part =~ /\r?\n\r?\n/) {
		my ($left, $right) = ($`, $');
		$left =~ s/[\r\n]+$//;
		$_[0]++;
		push(@{$data}, {values => "", headers => {}});
		if(&extract_headers($left, $data->[$_[0]]->{'headers'})) {
			if(my $error = &new_tmp_file($args->{'temp_dir'}, $data->[$_[0]])) { $r->log->warn($error), next; }
		}
		$part = $right;
		$h = 0;
	}
	if($part =~ /\r?\n--$boundary\r?\n/) {
		my ($left, $right) = ($`, $');
		&output_data($data->[$_[0]], $left) if($left);
		&multipart_data($r, $args, $data, $boundary, $len, 1, $right, $_[0]);
		$part = "";
	}
	if($part =~ /\r?\n--$boundary--[\r\n]*/) {
		my $left = $`;
		&output_data($data->[$_[0]], $left) if($left);
	}
	return();
}

sub delete {
	my $self = shift;
	map { $self->parms->unset($_); } @_;
	return();
}

sub delete_all {
	my $self = shift;
	$self->parms->clear();
	return();
}

sub param {
	my $self = shift;

	if(scalar(@_) > 1) {
		my %hash = @_;
		while(my ($k, $v) = each(%hash)) {
			my @transfer = (ref($v) eq "HASH") ? %{$v} : (ref($v) eq "ARRAY") ? @{$v} : ($v);
			my $first = shift(@transfer) || "";
			$self->parms->set($k => $first);
			map { $self->parms->add($k, $_); } @transfer;
		}
		return();
	}
	if(scalar(@_) == 1) {
		my $k = shift;
		return($self->parms->get($k));
	}
	return(keys(%{$self->parms}));
}

1;
__END__

=head1 NAME

Apache::ParseFormData - Perl extension for dealing with client request data

=head1 SYNOPSIS

  use Apache::RequestRec ();
  use Apache::RequestUtil ();
  use Apache::Const -compile => qw(DECLINED OK);
  use Apache::ParseFormData;

  sub handler {
    my $r = shift;
    my $apr = Apache::ParseFormData->new($r);

    my $scalar = 'abc';
    $apr->param('scalar_test' => $scalar);
    my $s_test = $apr->param('scalar_test');
    print $s_test;

    my @array = ('a', 'b', 'c');
    $apr->param('array_test' => \@array);
    my @a_test = $apr->param('array_test');
    print $a_test[0];

    my %hash = (
      a => 1,
      b => 2,
      c => 3,
    );
    $apr->param('hash_test' => \%hash);
    my %h_test = $apr->param('hash_test');
    print $h_test{'a'};

    $apr->notes->clear();

    return Apache::OK;
  }

=head1 ABSTRACT

The Apache::ParseFormData module allows you to easily decode and parse    
form and query data, even multipart forms generated by "file upload".
This module only work with mod_perl 2.

=head1 DESCRIPTION

C<Apache::ParseFormData> extension parses a GET and POST requests, with
multipart form data input stream, and saves any files/parameters
encountered for subsequent use.

=head1 Apache::ParseFormData METHODS 


=head2 new

Create a new I<Apache::ParseFormData> object. The methods from I<Apache>
class are inherited. The optional arguments which can be passed to the 
method are the following:

=over 3

=item temp_dir

Directory where the upload files are stored.

=item disable_uploads

Disable file uploads.

  my $apr = Apache::ParseFormData->new($r, disable_uploads => 1);

  my $status = $apr->parse_result;
  unless($status == Apache::OK) {
    my $error = $apr->notes->get("error-notes");
    ...
    return $status;
  }

=item post_max

Limit the size of POST data.

  my $apr = Apache::ParseFormData->new($r, post_max => 1024);

  my $status = $apr->parse_result;
  unless($status == Apache::OK) {
    my $error = $apr->notes->get("error-notes");
    ...
    return $status;
  }

=back

=head2 parse_result

return the status code after the request is parsed.

=head2 param

Like I<CGI.pm> you can add or modify the value of parameters within your
script.

  my $scalar = 'abc';
  $apr->param('scalar_test' => $scalar);
  my $s_test = $apr->param('scalar_test');
  print $s_test;

  my @array = ('a', 'b', 'c');
  $apr->param('array_test' => \@array);
  my @a_test = $apr->param('array_test');
  print $a_test[0];

  my %hash = (
    a => 1,
    b => 2,
    c => 3,
  );
  $apr->param('hash_test' => \%hash);
  my %h_test = $apr->param('hash_test');
  print $h_test{'a'};

You can create a parameter with multiple values by passing additional
arguments:

  $apr->param(
    'color'    => "red",
    'numbers'  => [0,1,2,3,4,5,6,7,8,9],
    'language' => "perl",
  );

Fetching the names of all the parameters passed to your script:

  foreach my $name (@names) {
    my $value = $apr->param($name);
    print "$name => $value\n";
  }

=head2 delete

To delete a parameter provide the name of the parameter:

  $apr->delete("color");

You can delete multiple values:

  $apr->delete("color", "nembers");

=head2 delete_all

This method clear all of the parameters

=head2 upload

You can access the name of an uploaded file with the param method, just
like the value of any other form element.

  my %file_hash = $apr->param('file');
  my $filename = $file_hash{'filename'};
  my $content_type = $file_hash{'type'};
  my $size = $file_hash{'size'};

  my ($fh, $path) = $apr->upload('file_0');

  for my $form_name ($apr->upload()) {
    my ($fh, $path) = $apr->upload($form_name);

    while(<$fh>) {
      print $_;
    }

    my %file_hash = $apr->param($form_name);
    my $filename = $file_hash{'filename'};
    my $content_type = $file_hash{'type'};
    my $size = $file_hash{'size'};
    unlink($path);
  }

=head2 set_cookie

Set the cookies before send any printable data to client.

  my $apr = Apache::ParseFormData->new($r);

  $apr->set_cookie(
    name    => "foo",
    value   => "bar",
    path    => "/cgi-bin/database",
    expires => time + 3600,
    secure  => 1,
    domain  => ".capricorn.com",
  );

Get the value of foo:

  $apr->param('foo');

Clean cookie:

  $apr->set_cookie(
    name    => "foo",
    value   => "",
    expires => time - 3600,
  );

=head1 SEE ALSO

libapreq, Apache::Request

=head1 CREDITS

This interface is based on the libapreq by Doug MacEachern.

=head1 AUTHOR

Henrique Dias, E<lt>hdias@aesbuc.ptE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Henrique Dias
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
