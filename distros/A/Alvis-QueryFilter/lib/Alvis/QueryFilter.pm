package Alvis::QueryFilter;

########################################################################
#
# A quick'n'dirty query filter
#
#   -- Kimmo Valtonen
#
########################################################################

use strict;
use warnings;

use Carp;
use Data::Dumper;

use Alvis::Treetagger;
use CQL::Parser;
use URI::Escape;

use strict;

our $VERSION = '0.3';
our $verbose = 0;

my ($ERR_OK,
    $ERR_CQL_PARSER_INST,
    $ERR_XML_PARSER,
    $ERR_NO_QUERY,
    $ERR_CQL_PARSE,
    $ERR_NONIMP_NODE_TYPE,
    $ERR_NO_SEQ_LIST,
    $ERR_TREETAGGER,
    $ERR_LEMMA_DICT,
    $ERR_APPLYING_TERM_NE,
    $ERR_APPLYING_TYPING,
    $ERR_APPLYING_ONTO,
    $ERR_STRUCT2XML,
    $ERR_CREATING_CAT_LIST,
    $ERR_CREATING_SEQ_LIST,
    $ERR_CREATING_CQL_TAIL,
    $ERR_NEED_BOTH_TERM_AND_NE
    )=(0..16);

my %ErrMsgs=($ERR_OK=>"",
	     $ERR_CQL_PARSER_INST=>"Instantiating CQL::Parser failed.",
	     $ERR_XML_PARSER=>"Instantiating the XML parser failed.",
	     $ERR_NO_QUERY=>"No query.",
	     $ERR_CQL_PARSE=>"CQL parsing failed.",
	     $ERR_NONIMP_NODE_TYPE=>'Non-implemented CQL node type.',
	     $ERR_NO_SEQ_LIST=>
			      "No current data structure representing the " .
			      "query expansion. No preceding UI2Zebra() " .
			      "call or we're out of sync. You'll get your " .
			      "money back.",
	     $ERR_TREETAGGER=>"Applying the treetagger failed.",
	     $ERR_LEMMA_DICT=>"Applying the lemma dictionary failed.",
	     $ERR_APPLYING_TERM_NE=>"Applying the terms and NEs failed.",
	     $ERR_APPLYING_TYPING=>"Applying the typing rules failed.",
	     $ERR_APPLYING_ONTO=>"Applying the ontology mappings failed.",
	     $ERR_STRUCT2XML=>"Converting the data structure into XML failed.",
	     $ERR_CREATING_CAT_LIST=>
	     "Extracting category part of query failed.",
	     $ERR_CREATING_SEQ_LIST=>
	     "Creating the list of possible expansions failed.",
	     $ERR_CREATING_CQL_TAIL=>"Converting the data structure to a CQL " .
	     "tail failed.",
	     $ERR_NEED_BOTH_TERM_AND_NE=>"We need both a term and a NE dictionary."
	     );

sub new
{
    my $proto=shift;
 
    my $class=ref($proto)||$proto;
    my $parent=ref($proto)&&$proto;
    my $self={};
    bless($self,$class);

    $self->_set_err_state($ERR_OK);

    $self->_init(@_);

    $self->{CQLParser}=new CQL::Parser();
    if (!defined($self->{CQLParser}))
    {
	$self->_set_err_state($ERR_CQL_PARSER_INST);
	return undef;
    }

    $Alvis::Treetagger::verbose = $verbose;
    &Alvis::Treetagger::reopen();
    $self->{termMaxLen} = 0;
    $self->{textFields} = "text";
    $self->{tcanon} = \&canonise_def;
    $self->{ncanon} = \&canonise_def;
    #  this must match the lemma indexing rules in alvis2index.xsl
    $self->{lemmaSearch} = "^[VNJ]";


    return $self;
}

sub _init
{
    my $self=shift;

    $self->{keepLemmas}=1;

    if (defined(@_))
    {
        my %args=@_;
        @$self{ keys %args }=values(%args);
    }

}

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

sub errmsg
{
    my $self=shift;
    
    return $self->{errstr};
}

############################################################################
#
#          Public methods
#
############################################################################

sub set_lemma
{
  my $self=shift;
  $self->{lemmaSearch} = shift;
}

sub set_text_fields
{
  my $self=shift;
  my $fields=shift;
  $fields =~ s/\s+/ /g;
  $fields =~ s/"//g;
  $self->{textFields} = $fields;
}
sub set_canon
{
  my $self=shift;
  $self->{tcanon} = shift();
  $self->{ncanon} = shift();
}
sub read_dicts
{
    my $self=shift;
    my $lemma_dict_f=shift;
    my $term_dict_f=shift;
    my $NE_dict_f=shift;
    my $typing_rules_f=shift;
    my $onto_nodes_f=shift;
    my $onto_mapping_f=shift;

    if (defined($lemma_dict_f))
    {
	$self->{lemma_dict}=$self->_read_lemma_dict($lemma_dict_f);
    }
    else
    {
	undef $self->{lemma_dict};
    }
    if (defined($term_dict_f))
    {
	$self->{term_dict}=$self->_read_term_dict($term_dict_f);
    }
    else
    {
	undef $self->{term_dict};
    }
    if (defined($NE_dict_f))
    {
	$self->{NE_dict}=$self->_read_NE_dict($NE_dict_f);
    }
    else
    {
	undef $self->{NE_dict};
    }
    if (defined($typing_rules_f))
    {
	$self->{typing_rules}=$self->_read_typing_rules($typing_rules_f);
    }
    else
    {
	undef $self->{typing_rules};
    }
    if (defined($onto_nodes_f))
    {
	$self->{onto_nodes}=$self->_read_onto_nodes($onto_nodes_f);
    }
    else
    {
	undef $self->{onto_nodes};
    }
    if (defined($onto_mapping_f))
    {
	$self->{onto_paths}=$self->_read_onto_mapping($onto_mapping_f);
    }
    else
    {
	undef $self->{onto_paths};
    }

    # print STDERR " Term dict. check:  'Northern blot' -> " .
    #  $self->{term_dict}->{&canonise_def('Northern blot')} . "\n";

    return 1;
}

sub cleanspaces() {
  $_ = shift();
  s/\s+/ /g;
  s/^ //g;
  s/ $//g;
  return $_;
}

sub _read_lemma_dict
{
    my $self=shift;
    my $f=shift;

    my %dict=();

    if (!defined(open(F,"<:utf8",$f)))
    {
	return undef;
    }

    while (my $l=<F>)
    {
	chomp $l;
	my ($form,$lemma,$pos)=split(/\t/,$l,-1);
	$form = &cleanspaces($form);
	$dict{lc($form)}{lemma}=&cleanspaces($lemma);
	$dict{lc($form)}{POS}=$pos;
    }

    close(F);

    return \%dict;
}

#  default method to standardise terms and named entities
#            lower case, ignore space and '-'
sub canonise_def {
  $_ = shift();
  s/\s+//g;
  s/\-//g;
  $_ = lc($_);
}

sub _read_term_dict
{
    my $self=shift;
    my $f=shift;

    my %dict=();
    my $term_max_len = 0;

    if (!defined(open(F,"<:utf8",$f)))
    {
	return undef;
    }

    while (my $l=<F>)
    {
	chomp $l;
	my ($form,$can)=split(/\t/,$l,-1);
	$form = &cleanspaces($form);
	$can = &cleanspaces($can);
	my $cf = &{$self->{tcanon}}($form);
	if ( $verbose && defined($dict{$cf}) && $dict{$cf} ne $can ) {
	  print STDERR "Term of form '$form' has canonical form '$can'\n"
	    . "   but maps to the another canonical form '$dict{$cf}'\n";
	}
	$dict{$cf}=$can;
	my @tt = split(/ /,$form);
	if ( scalar(@tt)> $term_max_len) {
	  $term_max_len = scalar(@tt);
	}
    }
    if ( $self->{termMaxLen}<$term_max_len ) {
      $self->{termMaxLen} = $term_max_len;
    }

    close(F);

    return \%dict;
}

sub _read_NE_dict
{
    my $self=shift;
    my $f=shift;

    my %dict=();
    my $term_max_len = 0;

    if (!defined(open(F,"<:utf8",$f)))
    {
	return undef;
    }

    while (my $l=<F>)
    {
	chomp $l;
	my ($form,$can)=split(/\t/,$l,-1);
	$form = &cleanspaces($form);
	$can = &cleanspaces($can);
	my $cf = &{$self->{ncanon}}($form);
	if (  $verbose && defined($dict{$cf}) && $dict{$cf} ne $can ) {
	  print STDERR "NE of form '$form' has canonical form '$can'\n"
	    . "   but maps to the another canonical form '$dict{$cf}'\n";
	}
	$dict{$cf}=$can;
	my @tt = split(/\s+/,$form);
	if ( scalar(@tt)> $term_max_len) {
	  $term_max_len = scalar(@tt);
	}
    }
    if ( $self->{termMaxLen}<$term_max_len ) {
      $self->{termMaxLen} = $term_max_len;
    }

    close(F);

    return \%dict;
}

sub _read_typing_rules
{
    my $self=shift;
    my $f=shift;

    my %dict=();

    if (!defined(open(F,"<:utf8",$f)))
    {
	return undef;
    }

    while (my $l=<F>)
    {
	chomp $l;
	my ($form,$type)=split(/\t/,$l,-1);
	$form = &cleanspaces($form);
	$type = &cleanspaces($type);
	$dict{$form}=$type;
    }

    close(F);

    return \%dict;
}

sub _read_onto_nodes
{
    my $self=shift;
    my $f=shift;

    my %dict=();

    if (!defined(open(F,"<:utf8",$f)))
    {
	return undef;
    }

    while (my $l=<F>)
    {
	chomp $l;
	my ($form,$onto_node)=split(/\t/,$l,-1);
	$form = &cleanspaces($form);
	$onto_node = &cleanspaces($onto_node);	
	$dict{$form}=$onto_node;
    }

    close(F);

    return \%dict;
}

sub _read_onto_mapping
{
    my $self=shift;
    my $f=shift;

    my %dict=();

    if (!defined(open(F,"<:utf8",$f)))
    {
	return undef;
    }

    while (my $l=<F>)
    {
	chomp $l;
	my ($node,$path)=split(/\t/,$l,-1);
	$node = &cleanspaces($node);
	$path = &cleanspaces($path);
	$dict{$node}=$path;
    }

    close(F);

    return \%dict;
}

sub transform   # just for testing and debugging
{
    my $self=shift;
    my $query=shift; # list of word forms
    
    my $expanded_query_struct=$self->_expand_qword_list($query);

    $self->{queryForm} = $query;
    $self->{finalForm} = "";
    
    my $query_XML=$self->_data_struct2XML($expanded_query_struct);

    return $query_XML;
}

#
# Given a list of word forms, expand
#
sub _expand_qword_list
{
    my $self=shift;
    my $query=shift; # list of word forms

    # print STDERR "Q: " . Dumper($query) . "\n";

    my $lemmatized_by_tagger=$self->_apply_treetagger($query);
    if (!defined($lemmatized_by_tagger))
    {
	$self->_set_err_state($ERR_TREETAGGER);
	return undef;
    }

    # print STDERR "LEM: " . Dumper($lemmatized_by_tagger) . "\n";
    
    my $lemmatized=
	$self->_apply_lemma_dict($lemmatized_by_tagger); # if one exists
    if (!defined($lemmatized))
    {
	$self->_set_err_state($ERR_LEMMA_DICT);
	return undef;
    }
    
    # print STDERR "LEMTAG: " . Dumper($lemmatized) . "\n";
    
    my $term_NE_expanded=$self->_apply_terms_and_NEs($lemmatized);
    if (!defined($term_NE_expanded))
    {
	$self->_set_err_state($ERR_APPLYING_TERM_NE);
	return undef;
    }
    # print STDERR "TERM: " . Dumper($term_NE_expanded) . "\n";
    
    
    my $typing_expanded=$self->_apply_typing_rules($term_NE_expanded); 
    if (!defined($typing_expanded))
    {
	$self->_set_err_state($ERR_APPLYING_TYPING);
	return undef;
    }

    my $onto_expanded=$self->_apply_onto($typing_expanded); 
    if (!defined($onto_expanded))
    {
	$self->_set_err_state($ERR_APPLYING_ONTO);
	return undef;
    }
    # print STDERR "FINAL: " . Dumper($onto_expanded) . "\n";

    return $onto_expanded;
}

#  extract query from SRU
sub UI2Query
{
    my $self=shift;
    my $SRU=shift;
    if ( /&query=([^\&]*)/ ) {
      return $1;
    }
    return "";
}

#
#  UI ---> Zebra  middle man
#
sub UI2Zebra
{
    my $self=shift;
    my $SRU=shift;

    my @expanded_SRU=();

    # extract the query
    my $query;
    my @p=split(/\&/,$SRU,-1);
    for my $p (@p)
    {
	if ($p=~/^query=(.*)$/)
	{
	    $query=$1;
	}
	else
	{
	    push(@expanded_SRU,$p); # so we can reconstruct
	}
    }
    if (!defined($query))
    {
	$self->_set_err_state($ERR_NO_QUERY,"SRU:\"$SRU\"");
	return undef;
    }
    $self->{queryForm} = $query;
    $self->{queryForm} =~ s/\&/\&amp;/g;
    $self->{queryForm} =~ s/</\&lt;/g;
    $self->{queryForm} =~ s/>/\&gt;/g;
    $self->{finalForm} = "";

    # decode percentage notation
    my $query_copy=$query;
    $query_copy=uri_unescape($query_copy);

    # parse the CQL
    my $parse_tree;
    eval
    {
        $parse_tree=$self->{CQLParser}->parse($query_copy);
    };
    if ($@)
    {
        chomp($query);
        $@=~s/(.*) at .* line [0-9]+\n/$1/o;
        $self->_set_err_state($ERR_CQL_PARSE,"Query:\"$query\".");
        return undef;
    }

    # Get a list of all possible text query word sequences (so this is
    # implicitly an OR of them)
    #
    my $t_qwords=[[]]; # help variable used in the recursion
    my $seq_list=
	$self->_get_text_qwords($parse_tree,$t_qwords);
    if (!defined($seq_list))
    {
	$self->_set_err_state($ERR_CREATING_SEQ_LIST);
	return undef;
    }

    # Get the categorising tail anded to the end
    #
    my $cats=&get_categories($parse_tree);
    if (!defined($cats))
    {
	$self->_set_err_state($ERR_CREATING_CAT_LIST);
	return undef;
    }

    # Important! Used in the following Zebra2UI, 'cause the
    # SRU response has nothing about the query. 
    # So...if used out of sync/with more than one client...kaboom!
    # Not my problem.
    $self->{currSeqList}=$seq_list;

    # print STDERR "Term elements: " . Dumper($seq_list) . "\n";

    #
    # Ok, create the 'tail' i.e. what we AND to the original query
    # as an OR of possible expansions
    #
    my $CQL_tail=$self->_data_struct2CQLtail($seq_list);
    if (!defined($CQL_tail))
    {
	$self->_set_err_state($ERR_CREATING_CQL_TAIL);
	return undef;
    }

    # print STDERR "QQ##$query##$cats##$CQL_tail\n";

    #$query='%28' . $query . '%29%20and%20' $CQL_tail;
    $query=$CQL_tail;
    if ( $cats ) {
      $query .= '%20and%20' . $cats;
    } 

    push(@expanded_SRU,"query=$query");

    $self->{finalForm} = $query;
    $self->{finalForm} =~ s/\&/\&amp;/g;
    $self->{finalForm} =~ s/</\&lt;/g;
    $self->{finalForm} =~ s/>/\&gt;/g;

    return join('&',@expanded_SRU);
}

#
#  Zebra ---> UI  middle man
#
sub Zebra2UI
{
    my $self=shift;
    my $SRU_response=shift; 
    
    # We need to know what the query was! It's not in the response.
    # Of course this is bloody dangerous if we get out of sync or
    # have more than 1 client. 
    #
    if (!defined($self->{currSeqList}))
    {
	$self->_set_err_state($ERR_NO_SEQ_LIST);
	return undef;
    }

    # 
    # Just convert it to our XML format to put into extraResponseData
    # I chose to just catenate <query> elements as an implicit OR..
    #
    my $query_XML=$self->_data_struct2XML($self->{currSeqList});
    if (!defined($query_XML))
    {
	$self->_set_err_state($ERR_STRUCT2XML);
	return undef;
    }

    ${$SRU_response} =~ s/<\/zs:searchRetrieveResponse>/<zs:extraResponseData>$query_XML<\/zs:extraResponseData><\/zs:searchRetrieveResponse>/;

    return 1;
}


#
# Recursive CQL parse tree traversal, results in picking out the relevant
# text query words in order. Too tired to explain.
#
sub _get_text_qwords
{
    my $self=shift;
    my $CQL_parse_node=shift;
    my $text_qwords=shift;

    my ($text_qwords_l,$text_qwords_r);

    # print STDERR "ENTRY:",Dumper($text_qwords); 

    if ($CQL_parse_node->isa("CQL::AndNode"))
    {
#	warn "AND";
	$text_qwords_l=$self->_get_text_qwords($CQL_parse_node->left(),
					       $text_qwords);
	$text_qwords_r=$self->_get_text_qwords($CQL_parse_node->right(),
					       $text_qwords_l);

	return $text_qwords_r;
    }
    elsif ($CQL_parse_node->isa("CQL::OrNode"))
    {
#	warn "OR";

	$text_qwords_l=$self->_get_text_qwords($CQL_parse_node->left(),
					       $text_qwords);
	$text_qwords_r=$self->_get_text_qwords($CQL_parse_node->right(),
					       $text_qwords);

	return [@$text_qwords_l,@$text_qwords_r]; 
    }
    elsif ($CQL_parse_node->isa("CQL::NotNode"))
    {
	$text_qwords_l=$self->_get_text_qwords($CQL_parse_node->left(),
					       $text_qwords);
	
	return $text_qwords_l;

    }
    elsif ($CQL_parse_node->isa("CQL::TermNode"))
    {
#	warn "TERM";

	my $qualifier=$CQL_parse_node->getQualifier();
	my ($index_set_name,$index_name)=split(/\./,$qualifier);
	
	if (!defined($index_name))
	{
	    $index_set_name=$self->{indexSetName};
	    $index_name=$qualifier;
	}
	
	my $term=$CQL_parse_node->getTerm();
	
	# Our partial hack solution: if it contains a space, leave as is.
	# Wray's hack on hack - keep space stuff, and deal with it differently
	if ( 1 || ( $term!~/\s/) )
	{
	    $term =~ s/\s+/\#\#/g;
	    if ($qualifier eq 'text' || $qualifier eq 'srw.ServerChoice')
	    {
		my @update=();
		for my $qwords (@$text_qwords)
		{
		    my @qw=@$qwords;
		    push(@qw,$term);
		    push(@update,[@qw]);
		}
		return \@update;
	    }
	}
    }
    
    return $text_qwords;
}

#
# Recursive CQL parse tree traversal, results in picking out
# the ANDed category part at the end
#
sub get_categories
{
    my $CQL_parse_node=shift;

    my ($text_catq_l,$text_catq_r);

#    print STDERR "ENTRY:",Dumper($text_catq); 

    if ($CQL_parse_node->isa("CQL::AndNode"))
    {
        #	warn "AND";
	$text_catq_l=&get_categories($CQL_parse_node->left());
	$text_catq_r=&get_categories($CQL_parse_node->right());
	if ( $text_catq_l && $text_catq_r ) {
	  return $text_catq_l . ' and ' .$text_catq_r;
	}
	return $text_catq_l . $text_catq_r;	
    }
    elsif ($CQL_parse_node->isa("CQL::OrNode"))
    {
	return ""; 
    }
    elsif ($CQL_parse_node->isa("CQL::NotNode"))
    {
	return "";

    }
    elsif ($CQL_parse_node->isa("CQL::TermNode"))
    {
#	warn "TERM";

	my $qualifier=$CQL_parse_node->getQualifier();
	
	# Our partial hack solution: if it contains a space, leave as is.
	# Wray's hack on hack - keep space stuff, and deal with it differently

	if ($qualifier ne 'text' && $qualifier ne 'srw.ServerChoice') {
	  return $CQL_parse_node->toCQL();
	} else {
	  return "";
	}
    }
    
    return "";
}

#
# Converts our expansion data structure to a CQL "tail"
#
sub _data_struct2CQLtail
{
    my $self=shift;
    my $seq_list=shift;

    my $query;
    my @seq_items=();
    for my $seq (@$seq_list)
    {
	my $ds=$self->_expand_qword_list($seq);

	my @items=();

	for (my $i=0;$i<scalar(@$ds);$i++)
	{
	    my ($token,$POS,$lemma,$max_type,$match_can_form,$pathtype)
	      = @{$ds->[$i]};

	    if ( $POS eq 'INDEX' && $token =~ /^([a-z0-9\-\_\.]+)=(.*)/ ) {
		push(@items,"$1%3D%22$2%22");
	    } elsif (defined($max_type))
	    {
		if ($max_type eq 'term_dict')
		{
		    my $surface_form=$token;
		    my $can_form=$match_can_form;
		    my $onto=$pathtype;
		    my $j;
		    for ($j=$i+1;$j<scalar(@$ds);$j++)
		    {
			my ($token,$POS,$lemma,$max_type,$match_can_form,
			    $onto_path)
			    =@{$ds->[$j]};
			if (!defined($max_type) || $max_type ne 'term_dict' 
				|| !defined($match_can_form) || $can_form ne $match_can_form )
			{
			    last;
			}
			$surface_form.=" $token";
			$onto=$onto_path;
		    }
		    
		    if ( defined($onto) && $onto ne "" )
		    {
			push(@items,"term%3D%22$onto$can_form%22"); # unclear
		    }
		    else
		    {
			push(@items,"term%3D%22$can_form%22");
		    }

		    $i=$j-1;
		}
		elsif ($max_type eq 'NE_dict')
		{
		    my $surface_form=$token;
		    my $can_form=$match_can_form;
		    my $type=$pathtype;
		    my $j;
		    for ($j=$i+1;$j<scalar(@$ds);$j++)
		    {
			my ($token,$POS,$lemma,$max_type,$match_can_form,$NE_type)
			    =@{$ds->[$j]};
			if (!defined($max_type) || $max_type ne 'NE_dict' 
				|| !defined($match_can_form) || $can_form ne $match_can_form )
			{
			    last;
			}
			$surface_form.=" $token";
			$type = $NE_type;
		    }

		    if ( ! defined($type) || $type eq "" ) {
			push(@items,"entity%3D%22$can_form%22");
		    } elsif ( $type !~ /\// ) {
			push(@items,"entity-$type%3D%22$can_form%22"); 
		    } else {
			push(@items,"entity%3D%22$type$can_form%22");
		    }


		    $i=$j-1;
		}
	    }
	    elsif (defined($lemma) && $POS =~ /$self->{lemmaSearch}/o
		    && $self->{keepLemmas})
	    {
		push(@items,"lemma%3D%22$lemma%22");
	    }
	    else {
	      push(@items,$self->_make_term($token));
	    }
	}
	
	push(@seq_items,"%28" . join('%20and%20',@items)  . "%29");
    }
    if ( scalar(@seq_items) <= 1 ) {
	$query = $seq_items[0];
    } else {
    	$query = "%28" . join('%20or%20',@seq_items)  . "%29";
    }
 
    return $query;
}


sub _make_term
{
    my $self=shift;
    my $term=shift;
    if ( $term !~/^\"/ || $term !~/\"$/ ) {
      $term="\"$term\"";
    } 
    if ( $self->{textFields} =~/ / ) {
      my $result = "";
      foreach my $f ( split(/ /,$self->{textFields}) )  {
	$result .= " or $f%3D$term";
      }
      $result =~ s/^ or //;
      return "($result)";
    }
    return $self->{textFields} . "%3D$term";
  }

#
# Converts our expansion data structure to XML that fits extraResponseData
#
sub _data_struct2XML
{
    my $self=shift;
    my $seq_list=shift;

    my $XML = "<filter>\n <input>" . $self->{queryForm} . "</input>\n";

#    Why was this here in the first place?
#    $XML.="<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";

    my @seq_items=();
    for my $seq (@$seq_list)
    {
	my $ds=$self->_expand_qword_list($seq);

	$XML.="<query xmlns=\"http://alvis.info/query/\"\n";
	$XML.="     form=\"" . join(' ',@$seq) . "\" >\n";

	for (my $i=0;$i<scalar(@$ds);$i++)
	{
	    my ($token,$POS,$lemma,$max_type,$match_can_form,$pathtype)
	      = @{$ds->[$i]};

	    if (defined($max_type))
	    {
		if ($max_type eq 'term_dict')
		{
		    my $surface_form=$token;
		    my $can_form=$match_can_form;
		    my $onto=$pathtype;
		    my $j;
		    for ($j=$i+1;$j<scalar(@$ds);$j++)
		    {
			my ($token,$POS,$lemma,$max_type,$match_can_form,
			    $onto_path)
			    =@{$ds->[$j]};
			if (!defined($max_type) || $max_type ne 'term_dict' 
				|| $match_can_form ne $can_form)
			{
			    last;
			}
			$surface_form.=" $token";
			$onto=$onto_path;
		    }
		    $XML.="<term>\n";
		    $XML.="  <form>$surface_form</form>\n";
		    $XML.="  <canonical_form>$can_form</canonical_form>\n";
		    if ( defined($onto) && $onto ne "" )
		    {
		        $onto =~ s/\/$//;
			$XML .= "  <ontology_path>$onto</ontology_path>\n";
		    }
		    $XML.="</term>\n";
		    $i=$j-1;
		}
		elsif ($max_type eq 'NE_dict')
		{
		    my $surface_form=$token;
		    my $can_form=$match_can_form;
		    my $type=$pathtype;
		    my $j;
		    for ($j=$i+1;$j<scalar(@$ds);$j++)
		    {
			my ($token,$POS,$lemma,$max_type,$match_can_form,$NE_type)
			    =@{$ds->[$j]};
			if ($max_type ne 'NE_dict' || $match_can_form ne $can_form)
			{
			    last;
			}
			$surface_form.=" $token";
			$type=$NE_type;
		    }
		    $XML.="<named_entity>\n";
		    $XML.="  <form>$surface_form</form>\n";
		    $XML.="  <canonical_form>$can_form</canonical_form>\n";
		    if ( defined($type) && $type ne "" ) {
		      if ( $type !~ /\// ) {
			$XML.="  <named_entity_type>$type</named_entity_type>\n";
		      } else {
			$XML.="  <ontology_path>$type</ontology_path>\n";
		      }
		    }
		    $XML.="</named_entity>\n";
		    $i=$j-1;
		}
	    }
	    elsif (defined($lemma)  && $POS =~ /$self->{lemmaSearch}/o
		   && $self->{keepLemmas})
	    {
		$XML.="<lemma>\n";
		$XML.="  <form>$token</form>\n";
		$XML.="  <canonical_form>$lemma</canonical_form>\n";
		$POS=$self->_map_POS($POS);
		$XML.="  <syntactic_category>$POS</syntactic_category>\n";
		$XML.="</lemma>\n";
	    }
	    else # no analysis
	    {
		$XML.="<text>$token</text>\n";
	    }
	}
	$XML.="</query>\n";
    }
    $XML .= " <output>" . $self->{finalForm} . "</output></filter>\n";

    return $XML;
}

sub _map_POS
{
    my $self=shift;
    my $POS=shift;

    if ($POS=~/^V.*/)
    {
	$POS='V';
    }
    elsif ($POS=~/^N.*/)
    {
	$POS='N';
    }

    return $POS;
}

sub _apply_nulltagger
{
    my $self=shift;
    my $query=shift;
    my @lemmatized=($query, 'SENT', undef);
    return \@lemmatized;
}

sub _apply_treetagger
{
    my $self=shift;
    my $query=shift;

    my $stringified=join(" ",@$query);

    my $tagged_txt=&Alvis::Treetagger::tag($stringified);
    my @lemmatized=();
    for my $l (split(/\n/,$tagged_txt))
    {
	my ($token,$POS,$lemma)=split(/\t/,$l);
	#   restore CD lemmas to the form
	if ( $POS eq "CD" ) {
	   $lemma = $token;
	}
	#  Treetagger will make some proper nouns lower case,
	#  so we assume in query text user *only* enters
	#  upper case on purpose
	   elsif ( $token eq ucfirst($token) 
		&& lc($token) eq $lemma ) {
		$lemma = $token;
	}
	push(@lemmatized,[$token,$POS,$lemma]);
    }
    
    return \@lemmatized;
}

sub _apply_lemma_dict
{
    my $self=shift;
    my $tagger_output=shift;

    my @lemmatized=();

    # Could be simplified, but don't have the energy any more
    if (defined($self->{lemma_dict}))
    {
	# not tested btw
	#
	for my $t (@$tagger_output)
	{
	    my ($token,$POS,$lemma)=@$t;

	    if ( $token =~ /^([a-z0-9\-\_\.]+)=(.*)/i ) {
	      $token =~ s/\#\#/ /g;
              push(@lemmatized,[$token,'INDEX',undef]);
	    } elsif ( $token =~ /\#\#/ ) {
	      #  Wray's hack on hack
	      $token =~ s/\#\#/ /g;
	      $token = "\"$token\"";
	      push(@lemmatized,[$token,'TEXT',undef]);	   
	    } elsif ( $token =~ /_/ ) {
              $token =~ s/_+/ /g;
              $token =~ s/ $//;
              $token =~ s/^ //;
              push(@lemmatized,[$token,'TAG',undef]);
	    } elsif ($lemma eq "<unknown>") # try to fix
	    {
		if (defined($self->{lemma_dict}{$token}{lemma}))
		{
		    my $actual_POS;
		    if (defined($self->{lemma_dict}{$token}{POS}))
		    {
			$actual_POS=$self->{lemma_dict}{$token}{POS};
		    }

		    push(@lemmatized,[$token,$actual_POS,
				      $self->{lemma_dict}{$token}{lemma}]);
		}
		else # mark as lacking
		{
		    push(@lemmatized,[$token,$POS,undef]);
		}
	    }
	    else
	    {
		push(@lemmatized,[$token,$POS,$lemma]);
	    }
	}
    }
    else # no lemma dictionary so mark as lacking
    {
	for my $t (@$tagger_output)
	{
	    my ($token,$POS,$lemma)=@$t;

	    if ( $token =~ /^([a-z0-9\-\_\.]+)=(.*)/i ) {
	      $token =~ s/\#\#/ /g;
              push(@lemmatized,[$token,'INDEX',undef]);
	    } elsif ( $token =~ /\#\#/ ) {
	      #  Wray's hack on hack
	      $token =~ s/\#\#/ /g;
	      $token = "\"$token\"";
	      push(@lemmatized,[$token,'TEXT',undef]);	   
	    } elsif ( $token =~ /_/ ) {
              $token =~ s/_+/ /g;
              $token =~ s/ $//;
              $token =~ s/^ //;
              push(@lemmatized,[$token,'TAG',undef]);
            } elsif ($lemma eq "<unknown>") {
		push(@lemmatized,[$token,$POS,undef]);
	    }
	    else
	    {
		push(@lemmatized,[$token,$POS,$lemma]);
	    }
	}
    }	

    return \@lemmatized;
}

sub _apply_terms_and_NEs
{
    my $self=shift;
    my $lemmatized=shift;

    my @exp=();

    if (!defined($self->{term_dict}) || !defined($self->{NE_dict}))
    {
	$self->_set_err_state($ERR_NEED_BOTH_TERM_AND_NE);
	return undef;
    }
    else
    {
	for (my $start=0; $start<scalar(@$lemmatized);)
	{
	    my ($token,$POS,$lemma)=@{$lemmatized->[$start]};

	    #  dont check the special cases
	    if ( $POS eq 'INDEX' || $POS eq 'TEXT' ) {
		$start++;
		next;
	    }

	    # find the longest match
	    my $max=0;
	    my $max_type;
	    my $max_form;
	    
	    #  longest possible match
	    my $maxmax = scalar(@$lemmatized)-$start;
	    my $term = "";

	    if ( $maxmax > $self->{termMaxLen} ) {
	      $maxmax = $self->{termMaxLen};
	    }
	    #  tags get checked without any following sequence
	    if ( $POS eq 'TAG' ) {
		$maxmax = 1;
	    }
	    for ( my $i=0; $i<$maxmax; $i++) {
	      if ( $i>0 ) {
	      	my $tpos = $lemmatized->[$start+$i]->[1];
		#  these types mark a hard boundary
		if ( $tpos eq 'INDEX' || $tpos eq 'TAG' || $tpos eq 'TEXT' ) {
			last;
		}
	      }
	      my $lemma;
	      if (!defined($lemmatized->[$start+$i]->[2]))
		{
		  $lemma=$lemmatized->[$start+$i]->[0];
		}
	      else
		{
		  $lemma=$lemmatized->[$start+$i]->[2];
		}
	      $term .= " " . $lemma;
	      my $max_match;
	      if ( defined($max_match=
			   $self->{term_dict}->{&{$self->{tcanon}}($term)}) ) {
		$max = $i+1;
		$max_type = 'term_dict';
		$max_form = $max_match;
	      } elsif ( defined($max_match=
				$self->{NE_dict}->{&{$self->{ncanon}}($term)}) ) {
		$max = $i+1;
		$max_type = 'NE_dict';
		$max_form = $max_match;
	      } 
	    }

	    if ($max)
	    {
		for (my $i=$start; $i<$start+$max;$i++)
		{
		    my ($token,$POS,$lemma)=@{$lemmatized->[$i]};
		    $lemmatized->[$i]=[$token,$POS,$lemma,$max_type,$max_form];
		}
		$start+=$max;
	    }
	    else
	    {
		$start++;
	    }
	}

	
    }	

    return $lemmatized;
}

sub _apply_typing_rules
{
    my $self=shift;
    my $lemmatized=shift;

    my @exp=();

    if (!defined($self->{typing_rules}))
    {
	# not an error
	return $lemmatized;
    }
    else
    {
	for (my $i=0; $i<scalar(@$lemmatized);$i++)
	{
	    my ($token,$POS,$lemma,$max_type,$match_can_form)=
		@{$lemmatized->[$i]};
# print STDERR "_apply_typing_rules: ($token,$POS,$lemma,$max_type,$match_can_form)\n";
# print STDERR "       maps -> " . $self->{typing_rules}{$match_can_form} . "\n";
	    if (defined($max_type) && $max_type eq 'NE_dict' && 
		defined($match_can_form) && 
		defined($self->{typing_rules}{$match_can_form}))
	    {
		$lemmatized->[$i]=
		    [$token,$POS,$lemma,$max_type,$match_can_form,
		     $self->{typing_rules}{$match_can_form}];
	    }
	}
	
    }	

    return $lemmatized;
}

sub _apply_onto
{
    my $self=shift;
    my $lemmatized=shift;

    my @exp=();

    if (!(defined($self->{onto_nodes}) && defined($self->{onto_paths})))
    {
	# not an error, but need both or nothing
	return $lemmatized;
    }
    else
    {
	for (my $i=0; $i<scalar(@$lemmatized);$i++)
	{
	    my ($token,$POS,$lemma,$max_type,$match_can_form)=
		@{$lemmatized->[$i]};
	    if ( defined($match_can_form) && 
		defined($self->{onto_nodes}{$match_can_form}))
	    {
		my $node=$self->{onto_nodes}{$match_can_form};
		if ( defined($self->{onto_paths}{$node}) )
		{
		  my $path = $self->{onto_paths}{$node};
		  if ( $path ne "" ) {
		    $lemmatized->[$i] =
		      [$token,$POS,$lemma,$max_type,$match_can_form,"$path/"];
		  }
		}
	    }
	}

	
    }	

    return $lemmatized;
}


1;
__END__

=head1 NAME

Alvis::QueryFilter - Perl module providing SRU query filtering

=head1 SYNOPSIS

   my $QF=Alvis::QueryFilter->new();

=head1 DESCRIPTION

Provides a query translation and filtering interface for an
SRU server.  Queries are first lemmatised by the Treetagger,
and then translated according to rules in a
set of dictionaries, and then fed to an SRU server.  The
results then have the query translation data added into the
<extraResponseData> field.  

Query translation uses a specific scheme for creating field
names to use, and these fields are supported by the underlying SRU server.

Words in double quotes are left as is.
The remaining words are lemmatised by the Treetagger and
contiguous sequences match the term and named entity rules.

Terms recognised in the input query will generate a 
I<term="words"> entry in the transformed query.  
If an ontology node exists for them,
the corresponding ontology path will be prepended giving
I<term="onto-path/words"> entry.
Named entities recognised in the
input query, where ontologies are applied, will generate
a 
I<entity="words"> or
I<entity="onto-path/words"> entry.
When typing is used for named entities, a
I<entity-type="words"> entry is made.

Words that are not used in either terms or named entities,
that are lemmatised create a
I<lemma="word"> entry.

=head1 METHODS

=head2 new()

Create object.

         my $QF=Alvis::QueryFilter->new();

=head2 read_dicts()

Sets the filenames for the linguistic resources, and loads them up.
Must be called once at the start.

   if (!$QF->read_dicts($lemma_dict_f, $term_dict_f, $NE_dict_f, 
			$typing_rules_f, $onto_nodes_f, $onto_mapping_f)) {
     die("Reading the dictionaries failed.");
   }

Dictionary rules apply to the lemmatised forms after the Treetagger has been used. 

$lemma_dict_f :   Lists (text-occurence,lemma,part-of-speech) for lemmatising to be done on words left as unknown by the Treetagger.  The part of speech is just annotation, so not used.

$term_dict_f :    Lists (text-occurence,canonical-form) for terms.

$NE_dict_f :   Lists (text-occurence,canonical-form) for named entities.

$typing_rules_f :    Lists (canonical-form,type) for named entities.  Types are short text items (e.g., 'species', 'company', 'person') used to categorise named entities when no ontology is in use.

$onto_nodes_f :    Lists (canonical-form,ontology-node) for terms and named entities that are located in the ontology.  If named entities occur here, $typing_rules_f should be empty.

$onto_mapping_f :    Lists (ontology-node,ontology-path) giving fully expanded path for each node.

Entries in "NEs" and "terms" are applied as rules to query words, with longest match applying first.  Once all these are done, the typing or ontology forms are applied.


=head2 set_canon()

Sets the functions used to convert terms and names to a canonical
form that will be used when matching against dictionaries. Call before
reading dictionaries.  This can be used to handle comment elements of term
matching such as (possibly dangerously) ignoring dashes.

       sub termcanonise { $_ = lc(shift());  s/[\s\-]//g; return $_; }
       sub namecanonise { $_ = shift();  s/[\s\-\.]//g; return $_; }
       $QF->set_canon(\&termcanonise,\&namecanonise);

=head2 set_lemma()

Sets the match field to identify whether a lemma located by Treetagger
should be searched in 
I<lemma> indexes or 
I<text> indexes.

       $QF->set_lemma("^[NVJ]");

=head2 set_text_fields()

Sets the text fields expected of CQL output.  Call before
reading dictionaries.
      
      $QF->set_text_fields("text anchortext dc.title");

Fields are extracted by splitting on spaces.

The query filter assumes unfielded query terms are with the CQL field 
"text", and any other fields should only occur conjoined to the
end of the query (i.e., not inside any other Boolean constructs).
On output, and with the above call to &set_text_fields(), 
every CQL terminal node of form text="words" will
be translated into the disjunct:

      ( text="words" OR anchortext="words" OR dc.title="words"  )

=head2 UI2Zebra()

Convert SRU request/input received from your HTTP server, for instance, and
do the query translation to generate a new SRU request ready
to send to the real SRU server.  Details of the query mapping are
stored with the object for later use by Zebra2UI().

      my $ToZebra=$QF->UI2Zebra($SRU);
      my $ua = LWP::UserAgent->new;
      my $response = $ua->get("http://localhost:10000/$ToZebra");

=head2 Zebra2UI()

Filter the XML-wrapped as a HTTP response, received from
the real SRU server to add the query translation data into the 
<extraResponseData> field as a <filter> entry.
The argument is a reference to the response text.

   my $ua = LWP::UserAgent->new;
   my $response = $ua->get("http://localhost:10000/$ToZebra");
   if ( ! $QF->Zebra2UI( $response->content_ref ) ) {
      print STDERR "Unable to insert query for $SRU\n";
   }
   #  $response now ready to send back

=head1 SEE ALSO

See 
B<Alvis::Treetagger>(3), 
B<run_QF.pl>(1).

See http://www.alvis.info/alvis/Architecture_2fFormats#queryfilter 
for the XML formats and the schema.

See http://www.ims.uni-stuttgart.de/projekte/corplex/TreeTagger/DecisionTreeTagger.html for the Treetagger.

=head1 AUTHOR

Kimmo Valtonen, and some packaging by Wray Buntine.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Kimmo Valtonen

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=cut
