package Apache::Config::Preproc::ifdefine;
use strict;
use warnings;
use Carp;

our $VERSION = '1.02';

sub new {
    my $class = shift;
    my $conf = shift;
    my $self = bless {}, $class;
    @{$self->{D}}{@_} = (1) x @_;
    return $self;
}

sub find_define {
    my ($self,$elt,$id) = @_;

    while (my $p = $elt->parent) {
	if (grep {
	      (split /\s+/, $_->value)[0] eq $id
	    } $p->directive('define')) {
	    return 1;
	}
    }
    return;
}

sub _changed_in_section {
    my ($self, $section, $id, $before) = @_;
    foreach my $d (reverse $section->select) {
	if ($before) {
	    if ($d == $before) {
		$before = undef;
	    }
	    next;
	}
	
	if ($d->type eq 'directive') {
	    if ($d->name =~ m/^(un)?define$/i && $d->value eq $id) {
		if ($1) {
		    $self->undefine($id);
		} else {
		    $self->define($id);
		}
		return 1;
	    }
	} elsif ($d->type eq 'section' && lc($d->name) eq 'virtualhost') {
	    # Need to descend into VirtualHost, because accorind to the
	    # Apache docs
            # see (https://httpd.apache.org/docs/2.4/mod/core.html#define):
	    # 
	    #   While [the Define] directive is supported in virtual host
	    #   context, the changes it makes are visible to any later
	    #   configuration directives, beyond any enclosing virtual host.
	    #
	    # The same is said about the UnDefine directive.
	    
	    return 1 if $self->_changed_in_section($d, $id);
	}
    }
    return 0;
}

sub is_defined {
    my ($self,$id,$d) = @_;

    unless ($self->{D}{$id}) {
	my $before = $d;
	while ($d = $d->parent) {
	    last if $self->_changed_in_section($d, $id, $before);
	    $before = undef;
	}
    }
    return $self->{D}{$id};
}

sub define {
    my ($self,$id) = @_;
    $self->{D}{$id} = 1;
}

sub undefine {
    my ($self,$id) = @_;
    delete $self->{D}{$id};
}

sub expand {
    my ($self, $d, $repl) = @_;
    if ($d->type eq 'section') {
	if (lc($d->name) eq 'ifdefine') {
	    my $id = $d->value;
	    my $negate = $id =~ s/^!//;
	    my $res = $self->is_defined($id, $d);
	    $res = !$res if $negate;
	    if ($res) {
		push @$repl, $d->select;
	    }
	    return 1;
	}
    }
    if ($d->type eq 'directive') {
	my $name = lc($d->name);
	if ($name eq 'define') {
	    $self->define($d->value);
	    return 1;
	} elsif ($name eq 'undefine') {
	    $self->undefine($d->value);
	    return 1;
	}
    }
    return 0;
}

1;
__END__

=head1 NAME    

Apache::Config::Preproc::ifdefine - expand IfDefine sections

=head1 SYNOPSIS

    $x = new Apache::Config::Preproc '/path/to/httpd.conf',
               -expand => [ qw(ifdefine) ];

    $x = new Apache::Config::Preproc '/path/to/httpd.conf',
               -expand => [
                   { ifdefine => [qw(SYM1 SYM2)] }
               ];

=head1 DESCRIPTION

Eliminates the B<Define> and B<UnDefine> statements and expands the
B<E<lt>IfDefineE<gt>> statements in the Apache configuration parse
tree. Optional arguments to the constructor are treated as the names
of symbols to define (similar to the B<httpd> B<-D> options).    
    
    
