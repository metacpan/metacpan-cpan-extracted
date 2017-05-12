package Alvis::Wikipedia::CatGraph;

use warnings;
use strict;

use Storable;

$Alvis::Wikipedia::CatGraph::VERSION = '0.1';

#############################################################################
#
#  Exported graph types 
#
#############################################################################

our ($TWO_TOP_LEVELS,    # top 2 levels of the graph
     $GIVEN_LIST         # a given list of categories
     )=(0..1);

#############################################################################
#
#     Global variables & constants
#
##############################################################################

my $DEF_ROOT='fundamental';
my $DEBUG=0;

my $DEF_METHOD=$TWO_TOP_LEVELS;

#############################################################################
#
#     Error message stuff
#
#############################################################################

my ($ERR_OK,
    $ERR_LOAD,
    $ERR_LOAD_UNDEF,
    $ERR_NO_ROOT_CAT,
    $ERR_UNDEF_LIST,
    $ERR_NONEXIST_CAT,
    $ERR_UNK_CAT_METHOD,
    $ERR_NO_GRAPH,
    $ERR_DUMP
    )=(0..8);
my %ErrMsgs=($ERR_OK=>"",
	     $ERR_LOAD=>"Loading a graph dump failed.",
	     $ERR_LOAD_UNDEF=>"Loaded an undefined graph.",
	     $ERR_NO_ROOT_CAT=>"Root category not found in the graph.",
	     $ERR_UNDEF_LIST=>"Undefined category list.",
	     $ERR_NONEXIST_CAT=>"Category in the category list does not " .
	     "appear in the given graph.",
	     $ERR_UNK_CAT_METHOD=>"Unrecognized categorization method.",
	     $ERR_NO_GRAPH=>"No graph.",
	     $ERR_DUMP=>"Dumping the graph failed."
   );


sub _set_err_state
{
    my $self=shift;
    my $errcode=shift;
    my $errmsg=shift;

    if (!defined($errcode))
    {
	confess("set_err_state() called with an undefined argument.");
    }

    if (exists($ErrMsgs{$errcode}))
    {
	if ($errcode==$ERR_OK)
	{
	    $self->{errstr}="";
	}
	else
	{
	    $self->{errstr}.=" " . $ErrMsgs{$errcode};
	    if (defined($errmsg))
	    {
		$self->{errstr}.=" " . $errmsg;
	    }

	}
    }
    else
    {
	confess("Internal error: set_err_state() called with an " .
		"unrecognized argument ($errcode).")
    }
}

sub clearerr
{
    my $self=shift;
    
    $self->{errstr}="";
}

sub errmsg
{
    my $self=shift;
    
    return $self->{errstr};
}

#############################################################################
#
#      Public methods
#
##############################################################################
 
sub new
{
    my $proto=shift;

    my $class=ref($proto)||$proto;
    my $parent=ref($proto)&&$proto;
    my $self={};
    bless($self,$class);


    $self->_init(@_);

    $self->_set_err_state($ERR_OK);

    return $self;
}

sub _init
{
    my $self=shift;

    $self->{root}=$DEF_ROOT;
    $self->{method}=$DEF_METHOD;

    if (defined(@_))
    {
        my %args=@_;
        @$self{ keys %args }=values(%args);
    }
}

sub dump_graph
{
    my $self=shift;
    my $f=shift;

    eval
    {
	store($self->{G},$f);
    };
    if ($@)
    {
	$self->_set_err_state($ERR_DUMP,"file: $f");
	return 0;
    }

    return 1;
}

sub load_graph
{
    my $self=shift;
    my $f=shift;

    eval
    {
	$self->{G}=retrieve($f);
    };
    if ($@)
    {
	$self->_set_err_state($ERR_LOAD,"file: $f");
	return 0;
    }
    if (!defined($self->{G}))
    {
	$self->_set_err_state($ERR_LOAD_UNDEF,"file: $f");
	return 0;
    }
    
    return 1;
}

sub load_path_length_map
{
    my $self=shift;
    my $f=shift;

    eval
    {
	$self->{pathLengthMap}=retrieve($f);
    };
    if ($@)
    {
	$self->_set_err_state($ERR_LOAD,"file: $f");
	return 0;
    }
    if (!defined($self->{pathLengthMap}))
    {
	$self->_set_err_state($ERR_LOAD_UNDEF,"file: $f");
	return 0;
    }
    
    return 1;
}

sub dump_path_length_map
{
    my $self=shift;
    my $f=shift;

    eval
    {
	store($self->{pathLengthMap},$f);
    };
    if ($@)
    {
	$self->_set_err_state($ERR_LOAD,"file: $f");
	return 0;
    }
    
    return 1;
}

sub build_path_length_map
{
    my $self=shift;
    my $list=shift;     # list of category candidates

    $self->{pathLengthMap}=();

    my $L1=0; my $L2=1; 

    if ($self->{method} eq $TWO_TOP_LEVELS)
    {
	if (!defined($self->{root}) || 
	    !exists($self->{G}{$self->{root}}))
	{
	    $self->_set_err_state($ERR_NO_ROOT_CAT);
	    return 0;
	}
	my %visited=($self->{root}=>1);
	$self->{pathLengthMap}{$self->{root}}{$self->{root}}=0;

	for my $c (@{$self->{G}{$self->{root}}})
	{
	    $visited{$c}=1;
	    $self->{pathLengthMap}{$c}{$c}=0;

	    for my $c2 (@{$self->{G}{$c}})
	    {
		$visited{$c2}=1;
		$self->{pathLengthMap}{$c2}{$c2}=0;

		for my $c3 (@{$self->{G}{$c2}})
		{
		    my %c3_visited=%visited;
		    $self->_link_descendants($c3,$c2,\%c3_visited);
		    undef %c3_visited;
		}
	    }
	}
	
    }
    elsif ($self->{method} eq $GIVEN_LIST)
    {
	if (!defined($list))
	{
	    $self->_set_err_state($ERR_UNDEF_LIST);
	    return 0;
	}

	my %visited=();

	for my $c (@$list)
	{
	    $visited{$c}=1;
	    $self->{pathLengthMap}{$c}{$c}=0;

	    for my $c2 (@{$self->{G}{$c}})
	    {
		if (!exists($visited{$c2}))
		{
		    %visited=();
		    $visited{$c}=1;
		    $self->_link_descendants($c2,$c,\%visited);
		}
	    }
	}
    }
    else
    {
	$self->_set_err_state($ERR_UNK_CAT_METHOD);
	return 0;
    }

    return 1;
}

sub _link_descendants
{
    my $self=shift;
    my $node=shift;
    my $ancestor=shift;
    my $visited=shift;

    my @stack=([$ancestor,$node]);
    while (scalar(@stack))
    {
	my $p=pop(@stack);
	my $n=pop(@$p);

	my $length=scalar(@$p) - 1;
	if (!defined($self->{pathLengthMap}{$n}{$ancestor}) || 
	    $length<$self->{pathLengthMap}{$n}{$ancestor})
	{
	    $self->{pathLengthMap}{$n}{$ancestor}=$length;
	}

	$visited->{$n}=1;

	for my $child (@{$self->{G}{$n}})
	{
	    if (!exists($visited->{$child}))
	    {
		push(@stack,[@$p,$n,$child]);
	    }
	}
    }
}

sub _add_to_cat_list
{
    my $self=shift;
    my $node=shift;
    my $visited=shift;
    my $list=shift;

    my @stack=($node);
    while (scalar(@stack))
    {
	my $n=pop(@stack);

	if (!exists($visited->{$n}))
	{
	    $visited->{$n}=1;
	    push(@$list,$n);
	}

	for my $child (@{$self->{G}{$n}})
	{
	    if (!exists($visited->{$child}))
	    {
		push(@stack,$child);
	    }
	}
    }
}

sub get_list_of_cats
{
    my $self=shift;
    
    if (!exists($self->{G})||!defined($self->{G}))
    {
	$self->_set_err_state($ERR_NO_GRAPH);
	return undef;
    }

    my @list=();

    if (!defined($self->{root}) || 
	!exists($self->{G}{$self->{root}}))
    {
	$self->_set_err_state($ERR_NO_ROOT_CAT);
	return 0;
    }
    my %visited=($self->{root}=>1);
    push(@list,$self->{root});
    
    for my $c (@{$self->{G}{$self->{root}}})
    {
	if (!exists($visited{$c}))
	{
	    $visited{$c}=1;
	    push(@list,$c);
	}
	
	for my $c2 (@{$self->{G}{$c}})
	{
	    if (!exists($visited{$c2}))
	    {
		$visited{$c2}=1;
		push(@list,$c2);
		$self->_add_to_cat_list($c2,\%visited,\@list);
	    }
	}
    }

    return @list;
}

sub get_two_top_levels_cats
{
    my $self=shift;
    my $root=shift;
    
    if (!exists($self->{G})||!defined($self->{G}))
    {
	$self->_set_err_state($ERR_NO_GRAPH);
	return undef;
    }

    if (defined($root))
    {
	$self->{root}=$root;
    }

    my @list=();

    if (!defined($self->{root}) || 
	!exists($self->{G}{$self->{root}}))
    {
	$self->_set_err_state($ERR_NO_ROOT_CAT);
	return 0;
    }
    
    my %visited=($self->{root}=>1);
    for my $c (@{$self->{G}->{$self->{root}}})
    {
	if (!exists($visited{$c}))
	{
	    $visited{$c}=1;
	    push(@list,$c);
	}
	
	for my $c2 (@{$self->{G}->{$c}})
	{
	    if (!exists($visited{$c2}))
	    {
		$visited{$c2}=1;
		push(@list,$c2);
	    }
	}
    }

    return @list;
}

sub get_relative_scores
{
    my $self=shift;
    my $cat_nodes=shift;

    my %scores=();

    my %lengths=();
    my ($min_length,$max_length)=(10000000,0);
    my (%lengths_per_c);
    for my $n (@$cat_nodes)
    {
	if (exists($self->{pathLengthMap}{$n}))
	{
	    for my $c (keys %{$self->{pathLengthMap}{$n}})
	    {
		my $l=$self->{pathLengthMap}{$n}{$c};
		if (!exists($lengths_per_c{$c}) || $l<$lengths_per_c{$c})
		{
		    $lengths_per_c{$c}=$l;
		}
	    }
	}
	else
	{
	    warn "No path length from \"$n\" to any of the categories!\n";
	}
    }

    for my $length (values %lengths_per_c)
    {
	if ($length<$min_length)
	{
	    $min_length=$length;
	}
	if ($length>$max_length)
	{
	    $max_length=$length;
	}
    }

    for my $n (@$cat_nodes)
    {
	if (exists($self->{pathLengthMap}{$n}))
	{
	    for my $c (keys %{$self->{pathLengthMap}{$n}})
	    {
		my $l=$self->{pathLengthMap}{$n}{$c};
		my $score;
		my $MAX=10;
		if ($max_length>$min_length)
		{
		    $score=$MAX*(1-($l-$min_length)/($max_length-$min_length));
		}
		else
		{
		    $score=$MAX;
		}
		if (!exists($scores{$c}) || $score>$scores{$c})
		{
		    $scores{$c}=$score;
		}
	    }
	}
    }

    return \%scores;
}

sub add_link
{
    my $self=shift;
    my $cat=shift;
    my $parent=shift;

    push(@{$self->{G}{$parent}},$cat);
}

1;
__END__

=head1 NAME

Alvis::Wikipedia::Graph

=head1 SYNOPSIS


=head1 DESCRIPTION

To be written.

=head1 METHODS

=head2 new()

=head2 HTML()

=head2 errmsg()

=head1 SEE ALSO

=head1 AUTHOR

Kimmo Valtonen, E<lt>kimmo.valtonen@hiit.fiE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kimmo Valtonen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
