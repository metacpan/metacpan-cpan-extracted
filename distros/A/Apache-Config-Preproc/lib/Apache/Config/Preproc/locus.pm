package Apache::Config::Preproc::locus;
use parent 'Apache::Config::Preproc::Expand';
use strict;
use warnings;
use Text::Locus;

our $VERSION = '1.03';

sub new {
    my $class = shift;
    my $self = bless $class->SUPER::new(@_), $class;
    $self->{filename} = $self->conf->filename;
    $self->{line} = 0;
    $self->{context} = [];
    return $self;
}

sub filename { shift->{filename} }

sub context_push {
    my ($self,$file) = @_;
    push @{$self->{context}}, [ $self->filename, $self->{line} ];
    $self->{filename} = $file;
    $self->{line} = 0;
}

sub context_pop {
    my $self = shift;
    if (my $ctx = pop @{$self->{context}}) {
	($self->{filename}, $self->{line}) = @$ctx;
    }
}

sub expand {
    my ($self, $d, $repl) = @_;

    # Prevent recursion
    return 0 if $d->can('locus');

    # Handle context switches due to include statements.
    if ($d->type eq 'directive') {
	if ($d->name eq '$PUSH$') {
	    if ($d->value =~ /^\"(.+)\"/) {
		$self->context_push($1);
		return 0;
	    }
	} elsif ($d->name eq '$POP$') {
	    $self->context_pop();
	    return 0;
	}
    }

    # Compute and attach a locus object.
    $self->{line}++;
    my $locus = new Text::Locus($self->filename, $self->{line});
    if ($d->type eq 'section') {
	$self->lpush($locus);
    } elsif ($d->type eq 'directive') {
	if ((my $nl = ($d->{raw}) =~ tr/\n//) > 1) {
	    my $l = $self->{line}+1;
	    $self->{line} += $nl-1;
	    $locus->add($self->filename, ($l..$self->{line}));
	}	
    } elsif ($d->type eq 'blank') {
        if ($d->{length} > 1) {
	    my $l = $self->{line}+1;
	    $self->{line} += $d->{length}-1;	    
	    $locus->add($self->filename, ($l..$self->{line}));
	}
    } elsif ($d->type eq 'comment') {
	if (my $nl = ($d->value//'') =~ tr/\n//) {
	    my $l = $self->{line}+1;
	    $self->{line} += $nl;
	    $locus->add($self->filename, ($l..$self->{line}));
	}
    }
    push @$repl, Apache::Config::Preproc::locus::node->derive($d, $locus);
    return 1;
}

sub lpush {
    my ($self,$locus) = @_;
    push @{$self->{postprocess}}, $locus;
}

sub lpop {
    my ($self) = @_;
    pop @{$self->{postprocess}}
}

sub lcheck {
    my ($self, $item) = @_;
    if ($self->{postprocess} && @{$self->{postprocess}}) {
	return ${$self->{postprocess}}[$#{$self->{postprocess}}]->format eq $item->locus->format;
    }
}

sub end_section {
    my ($self, $d) = @_;
    if ($self->lcheck($d)) {
	$self->lpop;
	$self->{line}++;
	if (my @lines = $d->locus->filelines($self->filename)) {
	    $d->locus->add($self->filename, (pop(@lines)+1..$self->{line}));
	}
    }
}

package Apache::Config::Preproc::locus::node;
use Apache::Admin::Config;
our @ISA = qw(Apache::Admin::Config::Tree);

sub derive {
    my ($class, $orig, $locus) = @_;
    my $self = bless $orig->clone;
    $self->{_locus} = $locus;
    return $self;
}

sub locus { shift->{_locus} }

sub clone {
    my ($self) = @_;
    my $clone = bless $self->SUPER::clone;
    $clone->{_locus} = $clone->{_locus}->clone();
    return $clone;
}

1;
__END__

=head1 NAME    

Apache::Config::Preproc::locus - attach file location to each parse node

=head1 SYNOPSIS

    $x = new Apache::Config::Preproc '/path/to/httpd.conf',
                -expand => [ qw(locus) ];

    foreach ($x->select) {
        print $_->locus
    }

=head1 DESCRIPTION

B<Locus> attaches to each node in the parse tree a B<Text::Locus> object
which describes the location of the corresponding statement in the source
file.  The location of a node can be accessed via the B<locus> method
as illustrated in the synopsis.    

Technically speaking, this module replaces each instance of
B<Apache::Admin::Config::Tree> in the parse tree with an instance of its
derived class B<Apache::Config::Preproc::locus::node>, which provides the
B<locus> accessor.    

=head1 SEE ALSO

L<Apache::Config::Preproc>

L<Text::Locus>    
    
=cut

    
    
    
    
	

