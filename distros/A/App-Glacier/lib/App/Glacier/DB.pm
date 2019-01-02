package App::Glacier::DB;
use strict;
use warnings;
use JSON;
use Carp;
use App::Glacier::Timestamp;
use parent 'Exporter';

use constant {
    ENCODE => 0,
    DECODE => 1
};

my %transcode = (
    'storable' => [
	# Encoder
	\&Storable::freeze,
	# Decoder
	\&Storable::thaw
    ],
    'json' => [
	# Encoder
	sub { JSON->new->convert_blessed(1)->encode(shift) },
	# Decoder
	sub { JSON->
		  new->
		  filter_json_object(sub { timestamp_deserialize $_[0] })->
		  decode(shift) }
    ]
);

sub mod_call {
    my ($class, $backend, $code) = @_;
    my $modname = $class . '::' . $backend;
    my $modpath = $modname;
    $modpath =~ s{::}{/}g;
    $modpath .= '.pm';
    require $modpath;
    return &{$code}($modname);
};

sub new {
    my ($class, $backend, %opts) = @_;
    my $v;
    my $self = bless { }, $class;

    if ($v = delete $opts{encoding}) {
	croak "unsupported encoding $v"
	    unless exists $transcode{$v};
	$self->{_encode} = $transcode{$v}[ENCODE];
	$self->{_decode} = $transcode{$v}[DECODE];
    }

    eval {
	$class->mod_call($backend, sub { $self->{_backend} = shift->new(%opts) })
    };
    if ($@) {
	# if ($@ =~ /Can't locate/) {
	#     croak "unknown backend: $backend";
	# }
	croak $@;
    }

    return undef unless $self->{_backend};
    
    return $self;
}

sub configtest {
    my ($class, $backend, $cfg, @path) = @_;
    my $res;
    eval {
	$res = $class->mod_call($backend,
				sub {
				    shift->configtest($cfg, @path)
				  });
    };
    if ($@) {
	croak $@;
    }
    return $res;
}

sub backend { shift->{_backend} }

sub decode {
    my ($self, $val) = @_;
    return $val unless $val && defined($self->{_decode});
    # This extra assignment is necessary to avoid the
    # "attempt to copy freed scalar" panic (reported at least for Perl
    # 5.18.2), which is apparently due to context mismatch.
    my $rv = &{$self->{_decode}}($val);
    return $rv;
}

sub encode {
    my ($self, $val) = @_;
    return $val unless defined($self->{_encode});
    return &{$self->{_encode}}($val);
}

sub retrieve {
    my ($self, $key) = @_;
    return $self->decode($self->backend->retrieve($key));
}

sub store {
    my ($self, $key, $val) = @_;
    return $self->backend->store($key, $self->encode($val));
}

sub foreach {
    my ($self, $code) = @_;
    croak "argument must be a CODE" unless ref($code) eq 'CODE';
    $self->backend->foreach(sub {
			       my ($key, $val) = @_;
			       &{$code}($key, $self->decode($val));
			    });
}

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;
    (my $meth = $AUTOLOAD) =~ s/.*:://;

    $self->backend->${\$meth}(@_);
}

1;
