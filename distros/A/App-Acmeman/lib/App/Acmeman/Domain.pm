package App::Acmeman::Domain;

use strict;
use warnings;
use Carp;
use Clone;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(CERT_FILE KEY_FILE CA_FILE);
our %EXPORT_TAGS = ( files => [ qw(CERT_FILE KEY_FILE CA_FILE) ] );
our $VERSION = '1.00';

use constant {
    CERT_FILE => 0,
    KEY_FILE => 1,
    CA_FILE => 2
};

sub uniq {
    my %h;
    map {
	if (exists($h{$_})) {
	    ()
	} else {
	    $h{$_} = 1;
	    $_
        }
    } @_; 
}

sub new {
    my ($class, %args) = @_;
   
    my $self = bless { }, $class;
    my $v;

    if ($v = delete $args{cn}) {
	$self->{_cn} = lc $v;
    }
    if ($v = delete $args{alt}) {
	if (ref($v) eq 'ARRAY') {
	    $self->{_alt} =  [ uniq(map { lc } @$v) ];
	} else {
	    $self->{_alt} = [ lc $v ];
	}
    }
    if ($v = delete $args{type}) {
	$self->{_cert_type} = $v;
    }
    if (($v = delete $args{certificate_file})
	|| ($v = delete $args{'certificate-file'})) {
	$self->{_file}[CERT_FILE] = $v;
    }
    if (($v = delete $args{ca_file})
	|| ($v = delete $args{'ca-file'})) {
	$self->{_file}[CA_FILE] = $v;
    }
    if (($v = delete $args{key_file})
	|| ($v = delete $args{'key-file'})) {
	$self->{_file}[KEY_FILE] = $v;
    }

    $v = delete($args{argument}) || '$domain';
    $v =~ s{\$}{\\\$};
    $self->{_argument} = qr($v);

    $self->{_postrenew} = delete $args{'postrenew'};
    
    croak "unrecognized arguments" if keys %args;
    return $self;
}

sub names {
    my $self = shift;
    if (wantarray) {
	return ($self->cn, $self->alt);
    } else {
	return $self->alt() + 1;
    }
}

sub contains {
    my $self = shift;
    my $val = lc shift;
    return grep { $_ eq $val } $self->names;
}   

sub _domain_cmp {
    my ($a,$b) = @_;

    carp "righthand-side argument should be a App::Acmeman::Domain"
	unless $b->isa('App::Acmeman::Domain');
    return $a->{_cn} cmp $b->{_cn};
}

sub _domain_plus {
    my ($a, $b) = @_;
    
    carp "righthand-side argument should be a App::Acmeman::Domain"
	unless $b->isa('App::Acmeman::Domain');

    $a = Clone::clone($a);
    push @{$a->{_alt}}, $b->cn
	unless $a->contains($b->cn);
    @{$a->{_alt}} = uniq($a->alt, $b->alt);
    return $a;
}
    
use overload
    cmp => \&_domain_cmp,
    '+' => \&_domain_plus,
    '""' => sub { $_[0]->cn };

sub cn {
    my $self = shift;
    return $self->{_cn};
}

sub alt {
    my $self = shift;
    if (wantarray) {
	return exists($self->{_alt}) ? (@{$self->{_alt}}) : ();
    } else {
	return exists($self->{_alt}) ? (0+@{$self->{_alt}}) : 0;
    }
}

sub file {
    my ($self, $type) = @_;
    return undef unless exists($self->{_file}[$type]);
    my $res = $self->{_file}[$type];
    $res =~ s{$self->{_argument}}{$self->cn}ge;
    return $res;
}

sub certificate_file {
    my $self = shift;
    return $self->file(CERT_FILE);
}

sub postrenew {
    my $self = shift;
    return $self->{_postrenew}
}

1;

