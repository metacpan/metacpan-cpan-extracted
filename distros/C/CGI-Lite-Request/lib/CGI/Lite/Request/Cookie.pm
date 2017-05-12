package CGI::Lite::Request::Cookie;

use CGI::Lite qw(url_encode url_decode);

=head1 NAME

CGI::Lite::Request::Cookie - Cookie objects for CGI::Lite::Request

=head1 SYNOPSIS

  %cookies = CGI::Lite::Cookie->fetch           # fetch all cookies
  $cookies = CGI::Lite::Cookie->fetch           # same but hash ref
   
  $cookie->name;                                # get
  $cookie->name('my_cookie');                   # set
   
  @value = $cookie->value;                      # for multiple values
  $value = $cookie->value;                      # array ref or simple scalar
  $cookie->value($simple_scalar);
  $cookie->value([ "one", "2", "III" ]);
   
  # mutators (simple get and set)
  $cookie->expires;
  $cookie->path;
  $cookie->domain;
  $cookie->secure;
  
  $cookie->as_string;                           # returns the cookie formatted
                                                # for use in an HTTP header

=head1 DESCRIPTION

This class is almost identical to the original L<CGI::Cookie>, except
in that it doesn't require the Cursed Gateway Interface (CGI.pm) to
function, instead it uses only methods provided by L<CGI::Lite> - a
module which lives up to its name.

=cut

sub fetch {
    my $class = shift;
    my $raw_cookie = $ENV{HTTP_COOKIE} || $ENV{COOKIE};
    return () unless $raw_cookie;
    my %results = $class->parse($raw_cookie);
    return wantarray ? %results : \%results;
}

sub raw_fetch {
    my $class = shift;
    my $raw_cookie = $ENV{HTTP_COOKIE} || $ENV{COOKIE};
    return () unless $raw_cookie;
    my %results;
    my($key,$value);

    my(@pairs) = split(/;\s+/, $raw_cookie);
    foreach (@pairs) {
	if (/^([^=]+)=(.*)/) {
	    $key = $1;
	    $value = $2;
	}
	else {
	    $key = $_;
	    $value = '';
	}
	$results{$key} = $value;
    }
    return \%results unless wantarray;
    return %results;
}

sub parse {
    my ($self,$raw_cookie) = @_;
    my %results;

    my(@pairs) = split(/;\s+/, $raw_cookie);
    foreach (@pairs) {
	my($key,$value) = split("=");
	my(@values) = map url_decode($_), split('&', $value);
	$key = url_decode($key);
	$results{$key} = $self->new(
            -name  => $key,
            -value => \@values
        );
    }
    return \%results unless wantarray;
    return %results;
}

sub new {
    my ($class, %param) = @_;

    my $value = $param{-value};

    ($param{-path} = $ENV{SCRIPT_NAME}) =~ s/[^\/]+$//
        unless $param{-path};

    my $self = bless {
        name  => $param{-name},
    }, $class;
    $self->value($value);

    foreach (qw[ path domain secure expires ]) {
        $self->$_($param{"-$_"}) if defined $param{"-$_"};
    }
    return $self;
}

sub as_string {
    my $self = shift;
    return "" unless $self->name;

    my (@fields, $domain, $path, $expires, $secure);

    push(@fields, "domain=$domain")   if $domain = $self->domain;
    push(@fields, "path=$path")       if $path = $self->path;
    push(@fields, "expires=$expires") if $expires = $self->expires;
    push(@fields, 'secure')           if $secure = $self->secure;

    my ($key) = url_encode($self->name);
    my ($cookie) = join("=", $key, join("&", map url_encode($_), $self->value));

    return join("; ", $cookie, @fields);
}

sub name {
    $_[0]->{name} = $_[1] if defined $_[1]; $_[0]->{name};
}

sub value {
    my ($self, $value) = @_;

    if (defined $value) {
        my @values;
        if (ref($value)) {
            if (ref($value) eq 'ARRAY') {
                @values = @$value;
            } elsif (ref($value) eq 'HASH') {
                @values = %$value;
            }
        } else {
            @values = ($value);
        }
        $self->{value} = \@values;
    }

    wantarray ? @{$_[0]->{value}} : $_[0]->{value};
}

sub expires {
    $_[0]->{expires} = $_[1] if defined $_[1]; $_[0]->{expires};
}

sub path {
    $_[0]->{path} = $_[1] if defined $_[1]; $_[0]->{path};
}

sub domain {
    $_[0]->{domain} = $_[1] if defined $_[1]; $_[0]->{domain};
}

sub secure {
    $_[0]->{secure} = $_[1] if defined $_[1]; $_[0]->{secure};
}

1;


=head1 AUTHOR

Richard Hundt <richard NO SPAM AT protea-systems.com>

=head1 ACKNOWLEDGEMENTS

Dr. Lincoln Stein and anybody who contributed to L<CGI::Cookie>
from which most of this code was stolen.

=head1 SEE ALSO

L<CGI::Lite>, L<CGI::Lite::Request>, L<CGI::Cookie>

=head1 LICENCE

This library is free software and may be used under the same terms as Perl itself

=cut
