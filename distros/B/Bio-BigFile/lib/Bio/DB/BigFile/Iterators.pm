package Bio::DB::BigFile::Iterators;

# nothing in here

package Bio::DB::BigFile::IntervalIterator;
use strict;

use Carp 'croak';

sub new {
    my $self   = shift;
    my ($bigfile,$options) = @_;
    my $bf     = $bigfile->bf;
    my $method = $self->_query_method();
    my $head   = $bf->$method($options->{-seq_id},
			      $options->{-start}-1,
			      $options->{-end},
			      $options->{-max}||0,
	)
	or return;
    return bless {
	head    => $head,   # keep in scope so not garbage collected
	seq_id  => $options->{-seq_id},
	current => $head->head,
	bigfile => $bigfile,
	options => $options,
    },ref $self || $self;
}

sub next_seq {
    my $self = shift;
    my $options = $self->{options};
    my ($filter,$strand,$type) = @{$options}{qw(-filter -strand -type)};

    my ($i,$f);

    for ($i = $self->{current};$i;$i=$i->next) {
	$f = $self->_make_feature($i,$type);
	next if defined $strand && $f->strand != $strand;
	last if !$filter || $filter->($f);
    }

    if ($i) {
	$self->{current} = $i->next;
	return $f;
    }
    else {
	$self->{current} = undef;
	return;
    }
}

sub _query_method {
    croak 'implement this method';
}

sub _feature_method {
    croak 'implement this method';
}

sub _make_feature {
    my $self     = shift;
    my ($raw_item,$type) = @_;
    $type      ||= 'region';
    my $method   = $self->_feature_method;
    return $method->new(-seq_id => $self->{seq_id},
			-start  => $raw_item->start+1,
			-end    => $raw_item->end,
			-score  => $raw_item->value,
			-type   => $type,
			-fa     => $self->{bigfile}->fa,
	);
}

##################################################################
package Bio::DB::BigFile::SummaryIterator;
use Carp 'croak';

sub new {
    my $self = shift;
    my ($bigfile,$options) = @_;
    my $bf     = $bigfile->bf;
    my $query_class = $self->_query_class();
    return bless {
	feature => $query_class->new(-seq_id => $options->{-seq_id},
				     -start  => $options->{-start},
				     -end    => $options->{-end},
				     -type   => 'summary',
				     -fa     => $bigfile->fa,
				     -bf     => $bigfile)
    },ref $self || $self;
}

sub next_seq {
    my $self = shift;
    my $d = $self->{feature};
    $self->{feature} = undef;
    return $d;
}

sub _query_class { croak 'implement this method' }

############################################################

package Bio::DB::BigFile::BinIterator;
use Carp 'croak';

sub new {
    my $self   = shift;
    my ($bigfile,$options) = @_;
    my $bf     = $bigfile->bf;

    my (undef,$bins) = $options->{-type} =~ /^(bin)(?::(\d+))?/i
	or croak "invalid call to _get_bin_stream. -type argument must be bin[:bins]";
    $bins ||= 1;

    my $method = $self->_query_method;
    my $arry   = $bf->$method($options->{-seq_id},
			      $options->{-start}-1,
			      $options->{-end},
			      $bins)
	or return;

    my $chrom_end = $bf->chromSize($options->{-seq_id});
    my $binsize   = ($options->{-end}-$options->{-start}+1)/$bins;
    return bless {
	array   => $arry,
	bigfile  => $bigfile,
	start   => $options->{-start},
	end     => $chrom_end,
	binsize => $binsize,
	seq_id  => $options->{-seq_id},
    },ref $self || $self;
}

sub next_seq {
    my $self = shift;
    my $filter = $self->{options}{-filter};

    my $array  = $self->{array};
    my $i      = shift @$array;
    my $f;
    while ($i) {
	$f = $self->_make_feature($i);
	$self->{start} += $self->{binsize} + 1;
	last if !$filter || $filter->($f);
	$i = shift @$array;
    }

    return $f if $i;
    return;
}

sub _make_feature {
    my $self = shift;
    my $raw_item = shift;
    my $end = int($self->{start}+$self->{binsize});
    $end    = $self->{end} if $end > $self->{end};
    my $feature_method = $self->_feature_method;
    return $feature_method->new(-seq_id => $self->{seq_id},
				-start  => int($self->{start}),
				-end    => $end,
				-score  => $raw_item,
				-type   => 'bin',
				-fa     => $self->{bigfile}->fa,
	);
}

sub _feature_method {
    croak 'implement this method';
}


##################################################################

package Bio::DB::BigFile::EmptyIterator;

sub new { my $self = shift; return bless {},ref $self || $self }
sub next_seq { return }


##################################################################

package Bio::DB::BigFile::GlobalIterator;

sub new {
    my $self = shift;
    my ($bigfile,$inner_iterator,$options) = @_;
    my $cl = $bigfile->bf->chromList or return;

    my $s =  bless {
	cl_head  => $cl,     # keep in scope so not garbage collected
	current  => $cl->head,
	bigfile  => $bigfile,
	options  => $options,
	inner_i  => $inner_iterator,
    },ref $self || $self;

    $s->{interval}  = $s->_new_interval($bigfile,$cl->head,$options);
    return $s;
}


sub next_seq {
    my $self = shift;
    my $c    = $self->{current} or return;

    my $next = $self->{interval}->next_seq;
    return $next if $next;
    
    # if we get here, then there are no more intervals on current chromosome
    # try more chromosomes
    while (1) {
	$self->{current}  = $self->{current}->next or return;  # out of chromosomes
	$self->{interval} = $self->_new_interval($self->{bigfile},$self->{current},$self->{options});
	my $next = $self->{interval}->next_seq;
	return $next if $next;
    }
}

sub _new_interval {
    my $self = shift;
    my ($bigfile,$chrom,$options) = @_;
    my $inner_iterator = $self->{inner_i};
    my %options = (%$options,
		   -seq_id => $chrom->name,
		   -start  => 1,
		   -end    => $chrom->size);
    return $inner_iterator->new($bigfile,\%options);
}

1;
