##################################################################
package AnyData::Format::XML;
##################################################################
# an AnyData format parser for XML
# by Jeff Zucker <jeff@vpservices.com>
##################################################################

use strict;
use warnings;
use AnyData::Format::Base;
use AnyData::Storage::RAM;
use XML::Twig;
use vars qw( @ISA  $DEBUG $VERSION);
@AnyData::Format::XML::ISA = qw( AnyData::Format::Base );

$VERSION = '0.12';

sub seek    { 1 }
sub get_pos { 1 }
sub go_pos  { 1 }

sub new {
    my $class = shift;
    my $self  = shift ||  {};
    $self->{export_on_close} = 1;
    $self->{slurp_mode}      = 1;
    if ($self->{col_names}) {
        ## something goes here :-)
    }
    return bless $self, $class;
}

sub storage_type { 'PassThru'; }

sub truncate {
    my $self = shift;
    my $data = shift; # from SQL::Statement, ignored
    for my $e( $self->{twig}->root->descendants  ) {
        next unless $e->gi eq 'delete__';
        $e->delete;
    }
    undef $self->{last_before_delete};
}
sub push_row {
    my $self = shift;
    my @fields  = @_;
    my @ch = caller 3;          # tied-hash
    my @cd = caller 4;          # DBD
    my $hash_caller = $ch[3] || '';
    my $dbd_caller  = $cd[3] || '';
    my @f  = caller 4;
    if ($dbd_caller =~ /SQL/ ) {
        # DELETE | UPDATE | INSERT
        if ( !$self->{last_before_delete} && $dbd_caller !~ /INSERT/ ) {
            $self->{last_before_delete} =  1;
            my @children = $self->{twig}->root->descendants;
            for my $e(@children) {
                 next unless $e->path eq $self->{record_tag}->path;
                 next if $e->cmp($self->{record_tag}) == 0;
                 $e->set_gi("delete__")
     	    }
     	}
        #$self->{twig}->print; exit;
        return $self->insert_record(\@fields);
    }
    $self->insert_record(\@fields);
}

sub insert_record {
    my $self = shift;
    my $row  = shift;
#print "@$row\n";
    my $rect          = $self->{record_tag};
    my $col_structure = $self->{col_structure};
    my @tags  = @{$col_structure->{col_names}};
    my @cols  = @{$col_structure->{pretty_cols}};
    my $is_atr  = $col_structure->{amap};
    my $p = $rect->path;
    my $has_parent_atr;
    for my $atr(keys %$is_atr) {
        $has_parent_atr++ unless $atr =~ /^$p/;
    }
    my $col2tag   = $col_structure->{col2tag} || {};

    my $elt= new XML::Twig::Elt($rect->gi);           # CREATE ELEMENT
    my $par;
    my $par_name = $rect->parent->gi;
    if ($has_parent_atr) {
       $par = new XML::Twig::Elt($rect->parent->gi);  # CREATE PARENT
     }
    my $rowhash;
    @{$rowhash}{@cols} = @$row;
    for my $i(0..$#cols) {
       my $tag   = $tags[$i];
       my $col   = $cols[$i];
       my $value = $rowhash->{$col};
       $tag ||=  $col2tag->{$col};
       my($path,$name) = $tag =~ m!^(.*)/([^/]*)$!;
       if ($is_atr->{$tag} && defined $value) {
         if ($tag =~ /^$p/) {
          $elt->set_att($name,$value);             # ADD ELT ATTRIBUTE
	 } 
         else {
          $par->set_att($name,$value);         # ADD PARENT ATTRIBUTE
	 }
       }
       elsif (defined $name && defined $value) {
           my $kid= new XML::Twig::Elt($name);     # CREATE CHILD
           $kid->set_text($value);                 # ADD TEXT TO CHILD
           $kid->paste('last_child',$elt);         # PASTE CHILD INTO ELEMENT
       }
    }
    if ($has_parent_atr) {
          $elt->paste('last_child',$par);          # PASTE ELT INTO PARENT
          my $last = $rect->parent->parent->last_child($par_name);
          $par->paste('after',$last);              # PASTE PARENT INTO TREE
    }
    else {
        my $last = $rect->parent->last_child($rect->gi);
        $elt->paste('after',$last);                 # PASTE ELEMENT INTO TREE
    }
    #$self->{twig}->print;
}

sub delete_record {
    #my @calls = caller 3;
    #my $call  = $calls[3] || '';
    #return if $call =~ /UPDATE/i;
    #print "$call\n";
    my $self = shift;
    my $elt  = $self->{prev_element};
    my $rec  = $self->{record_tag};
    my $p  = $rec->path;
     my $new = $elt->prev_elt($rec->gi);
    $elt = $new if $elt->path !~ /^$p/;
    $self->{skip} = 1 if !$elt;
    return undef unless $elt;
    $elt->delete;
}

sub DESTROY {
    return;
    print "XML DESTROYED";
    my $self = shift;
    if ( $self->{storage}->{fh}
      && $self->{storage}->{open_mode} ne 'r'
     ){
        $self->export( $self->{storage} );
    }
    #undef $self->{twig};
    #undef $self->{storage}->{fh};
}

sub read_fields {
    my $self = shift;
    my $c = $self->{current_element};
    return undef unless defined $c;
    $c = $self->{current_element} = $c->next_elt($c->gi)
         if $c->att('record_tag__');
    $self->{prev_element} = $self->{current_element};
    $self->{current_element} = $c->next_elt($c->gi) if $c;
    return $self->process_element( $self->{prev_element} );
}

sub process_element {
    my $self = shift;
    my $element   = shift;
    my @col_names  = @{ $self->{col_structure}->{col_names} };
    my @row;
    my $parent = $element->parent;
    my $values = { $element->path => $element->text };
    my $par_ats = {};
       $par_ats = $parent->atts if $parent;
    my $elt_ats = $element->atts || {};
    while( my($att_key,$att_val) = each %$par_ats) {
        $values->{$parent->path.'/'.$att_key} = $att_val;
    }
    while( my($att_key,$att_val) = each %$elt_ats) {
        $values->{$element->path.'/'.$att_key} = $att_val;
    }
    for my $kid($element->children) {
        if ( defined $values->{$kid->path} ) {
 	    if (!ref $values->{$kid->path}) {
               $values->{$kid->path} = [ $values->{$kid->path} ] ;
	    }
            push ( @{ $values->{$kid->path} }, $kid->text );
        } 
        else {
	  $values->{$kid->path} = $kid->text;
	}
    }
    for my $col(@col_names) {
        if (ref $values->{$col}) {
           @row = (@row,@{$values->{$col}});
        }
        else {
           push @row, $values->{$col};
	}

    }
    # use Data::Dumper; print Dumper $values, Dumper \@row; exit;
    return  @row;
}


sub seek_first_record {
    my $self = shift;
    return unless $self->{twig} and $self->{twig}->root;
    $self->{current_element} = $self->{record_tag};
}
sub push_names {
    my $self      = shift;
    my $col_names = shift || $self->{col_names};
    #my @c= caller 1; die $c[3]."!!!";
    my $str = "<table>\n  <row record_tag__='1'>\n";
    #print "CREATING";
    for (@$col_names) {
        $str .= "    <$_>dummy__</$_>\n";
    }
    $str .= "  </row>\n</table>\n";
    $str = $self->{template} if $self->{template};
    if ( $self->{dtd} ) {
       $str = $self->{dtd} if $self->{dtd};
       my $root = $str;
       $root =~ s/.*<!DOCTYPE\s+(\S+)\s+.*/$1/ms;
       $str .= "\n\n<$root></$root>";
       #die $str;
    }
    $self->get_data( $str );
    return $self->{col_names};
}

sub import { 
    my $self = shift; 
    my $data = shift; 
    my $storage = shift; 
    $self->init_parser($storage,$data); 
    return $self->get_data($data,$storage->{col_names});
}

####
# GET DATA FROM STRING
###
sub init_parser {
    my $self    = shift;
    my $storage = shift;
    my $fh_or_str = shift;
    return if 'co' =~ /$storage->{open_mode}/;
#print "   INIT ...";
#print "HAS RECS\n" if $storage->{recs};
#print "HAS DATA\n" if ref $storage->{file} eq 'HASH';
    $fh_or_str ||= $storage->{fh} if $storage->{fh};
    $fh_or_str  ||= $storage->{file}->{data} if ref $storage->{file} eq 'HASH';
    $fh_or_str  ||= $storage->{recs};
#    $fh_or_str ||= join('',@$fh_or_str) if ref $fh_or_str eq 'ARRAY';
#print $fh_or_str; exit;
###z    $self->create_new_twig( $self->{col_names} );
    my $rv = $self->get_data( $fh_or_str,$self->{col_names} );
    return undef unless $rv;
    $self->{current_element} = $self->{twig}->root;
    $storage->{col_names} = $self->{col_names};
    return 1;
}

sub create_new_twig {
    my $self = shift;
    my $flags = $self;
    my $root_tag            = $flags->{root_tag};
    my $depth_limit         = $flags->{depth_limit};
#    $flags->{twig_flags}->{TwigRoots} = {$root_tag=>'1'} if $root_tag;
#    $flags->{twig_flags}->{KeepEncoding}     ||= 1;
#    $flags->{twig_flags}->{ProtocolEncoding} ||= 'ISO-8859-1';
    $flags = $self->check_twig_options($flags);
    $self->{twig}= new XML::Twig(%{$flags});
    #$self->{twig}= new XML::Twig(%{$flags->{twig_flags}});
}

sub read_dtd {
    my $self = shift;
    my $twig = shift;
#print Dumper $self->{dtd}; exit;
    my $record_tag = $self->{record_tag};
    my $col_names =  $self->{col_names};
        $col_names = $self->{dtd}->{elt_list};
        my $newc;
        my $colh;
        #print Dumper $self->{dtd}; exit;
        my $col_text;
        for my $col(@$col_names) {
            while (my($k,$v) = each %{ $self->{dtd}->{model} } ) {
                if ($v =~ /(#P*CDATA)/ ) {
                   $col_text->{"$k$1"}++;
    	        }
                if ($v =~ /[(\s,]+$col[)\s,]+/ ) {
                   my @path  = ($k,$col);
                   push @$newc, \@path;
                   $colh->{$col} = $k;
    	        }
	     }
	}
        $col_names = [];
        my $done;
        my $nh;
        while (!$done) {
            $done = 1;
            my $i;
            for $i(0..scalar @$newc -1) {
  	        my $cur = $newc->[$i]->[0];
#                $cur =~ s"^.*/([^/]+)$"$1";
#print "$cur : ";
  	        my $path = $colh->{ $cur };
                my $p;
  	        if ($path) {
                    $p = $newc->[$i]->[0] = $path . '/' . $newc->[$i]->[0];
            #        delete $colh->{$cur};
                    $nh->{$cur} = $p;
                    $done=0;
	        }
                while (my($k,$v)=each %$nh) {
                   if ( $cur =~ m"^$k/(.*)") {
                      $newc->[$i]->[0] = $v . '/' . $1;
                      $done = 0;
                   }
                }
	    }
	}
        #@array = grep(!$is_member{$_}++, @array);
        my %is_member;
        for my $row (@$newc) {
            my $c = '/' . $row->[0] . '/' . $row->[1];
            push @$col_names, $c if !$is_member{$c};
            $is_member{$c}++;
        }
        # put in order by depth
        @$col_names = sort {
            my $x=$a; 
            my $y=$b; 
            $x =~ s"[^/]""g;; $x=length $x;
            $y =~ s"[^/]""g;; $y=length $y;
           $x <=> $y; 
        } @$col_names;
        $record_tag ||= $col_names->[0];
        $record_tag =~ s".*/([^/]+)$"$1";
 #       $record_tag = $twig->first_elt($record_tag) 
 #                   || die "Can't find column '$record_tag'!". $@;
        #print $record_tag, Dumper $col_names; exit;
        my %done;
	for my $c(@$col_names) {
           my @tags = split '/', $c;
           shift @tags; # remove root
           for my $i(0..$#tags) {
               my $t = $tags[$i];
               next if $done{$c.$t};
               next unless  $c =~ m"/$t$";
#               print "$c:$t\n";
#               next if $done{$t};
               $done{$c.$t}++ ; 
               my $nxt = $twig->root->next_elt($t);
               next if $nxt and $nxt->path =~ /^$c/;
               next if $t eq $twig->root->gi;
               my $p= $tags[$i-1];
               my $pos = $twig->root->next_elt($p);
               $pos ||= $twig->root;
               my $e= new XML::Twig::Elt($t);
               #if ($col_text->{$e->gi.'#PCDATA'}) {
               #     $e->append_pcdata("xxx");
	       #}
               $e->paste('last_child',$pos);
             #  if ($col_text->{$e->gi.'#PCDATA'} ) {
              #      print $e->gi.'#PCDATA'."\n";
                #    $twig->root->next_elt($e->gi)->append_pcdata('x');
	      # }
	   }
	}
        my $atts;
        while (my($k,$v)=each%{$self->{dtd}->{att}}) {
           my $cur = $twig->root->next_elt($k);
           next unless $cur;
               while (my($k2,$v2)=each%{$v}) {
###                   $cur->set_att($k2,"");
                   $atts->{$cur->path.'/'.$k2}=$k2;
#print "[".$cur->path.'/'.$k2."]";
               }
        }
        $record_tag ||= $twig->root->first_child->gi;
        $record_tag = $twig->root->next_elt($record_tag)
                   || die "Couldn't find column '$record_tag'!";
        $newc = [];
        my $found;
        for my $org(@$col_names) {
           my $x = $org;
           $x =~ s".*/([^/]+)$"$1";
           my $p =$record_tag->parent->path;
           next unless $org =~ /^$p/;
           #next unless $p =~ /^$_/;
           while (my($k,$v)=each%$atts) {
             next if $found->{$k};
	     if ( $k =~ m"$p/([^/]+)$" 
               or  $k =~ m"$p/([^/]+/[^/]+)$"
                ) {
#print "$k\n";
               push @$newc, $k;
               $found->{$k}++;
	     }
	   }
           push @$newc, $org if $col_text->{$x.'#PCDATA'}
                           or $col_text->{$x.'#CDATA'};
        }
        #unshift @$newc, $record_tag->gi unless $found;
#die Dumper $newc;
#$twig->print; exit;

        my $elt = $twig->root;
    if (!$self->{recs}) {
        while ( $elt = $elt->next_elt ) {
            $elt->set_att('xstruct__','1');
	}
        $record_tag->set_att('record_tag__','1');
    }
        #########
        # COMMENT THIS TO SEE STRUCTURE TAGS
        #
        $self->{destroy}++;

#print Dumper $record_tag->gi,$newc, $atts;
return( $record_tag,$newc, $atts);
#$twig->print; exit;
}

sub get_structure {
    my $self = shift;
    my $twig = shift;
    my $record_tag = $self->{record_tag};
#    $record_tag ||= $self->{table_name};
    my $col_names =  $self->{col_names};
    if ($self->{dtd}) {
        return $self->read_dtd($twig)
    }
    $record_tag = $twig->first_elt($record_tag) if $record_tag;
    $record_tag ||= $twig->root->first_child;
#print $record_tag->gi;
#    if (!$record_tag) {
#       $record_tag = $twig->root->first_child;
#       if ( $record_tag
#        and $record_tag->first_child
#        and !$record_tag->contains_text
#        and !$record_tag->first_child->contains_text
#       ) {
#          $record_tag = $record_tag->first_child;
#       }
#    }

    $self->{record_tag} = $record_tag;
    if ($self->{create}) {
        my $elt = $twig->root;
        while ( $elt = $elt->next_elt ) {
            $elt->set_att('xstruct__','1');
	}
###z# print "1";
       $record_tag->set_att('record_tag__','1');
    }
    if ($col_names) {
        @$col_names = map {
            my $o = $_;
            if ($o !~ m"/") {
              $o = $twig->first_elt($o)->path;
	    }
            $o;
        } @$col_names;
    }
    else {
        @$col_names = map {$_->path} $record_tag->descendants;
#die join "\n",@$col_names;
        my $newcolz = [];
        my %hashz;
        for (@$col_names) {
            next unless m"/#PCDATA|/#CDATA";
            next if $hashz{$_};
            push @$newcolz, $_;
            $hashz{$_}++;
	}
        $col_names = $newcolz;
    }
#    my $oldcols = $col_names;
#    $col_names = [];
#print join "\n", @$col_names; exit;
    my $atts;
    my @atts_to_check = ($record_tag,$record_tag->descendants);
#print $record_tag->gi,"\n";
    if ($record_tag->parent and $record_tag->parent->parent) {

        unshift @atts_to_check, $record_tag->parent;
    }
    my $has_record_tag = 1 if  $record_tag->att('record_tag__');
#print $has_record_tag ? 'HAS' : 'NONE';
#$twig->print;
#print $record_tag->path,"!\n";
#    for (keys %{$record_tag->atts}) { print "$_#"; }
    my @att_col;
    for my $t(@atts_to_check) {
       my $ats = $t->atts;
       next unless $ats;
       delete $ats->{record_tag__};
#       push @$col_names, $t->path if $t->is_text;
#       print $t->path . '/' . $_ for keys %$ats;
#       unshift @$col_names, $t->path . '/' . $_ for keys %$ats;
       push @att_col, $t->path . '/' . $_ for keys %$ats;
       #unshift @$atts, $ats->{$_} for keys %$ats;
       $atts->{$t->path . '/'. $_} = $_ for keys %$ats;
    }
    @$col_names = (@att_col,@$col_names);
    @$col_names = map {s"/#P*CDATA""; $_}  @$col_names;
    #print join "\n",@$col_names;

###z# print 2;
#    $record_tag->set_att('record_tag__','true');
     $record_tag->set_att('record_tag__','true') if $record_tag->text =~/dummy__/;
#     $record_tag->set_att('xstruct__','true') if $record_tag->text =~/dummy__/;
#
    #if ($has_record_tag) { $twig->print; exit; } 
    return($record_tag,$col_names,$atts) if $has_record_tag;

    my $cols;
    @$cols = map {$_} @$col_names;
    my $elt= new XML::Twig::Elt($record_tag->gi);
    for my $a(keys %$atts ) {
        $a =~ s".*/([^/]+)$"$1";
        next if $a eq 'record_tag__';
        next unless $record_tag->att($a);
        $elt->set_att($a,'');
    }
    for my $c(@$cols ) {
        next if $atts->{$c};
        next if $c =~ m"/#PCDATA";
        $c =~ s"/#PCDATA"";
        $c =~ s".*/([^/]+)$"$1";
        my $e= new XML::Twig::Elt($c);
        $e->paste('last_child',$elt);
    }
    my $par;
    if ($record_tag->parent and $record_tag->parent->parent) {
        $par= new XML::Twig::Elt($record_tag->parent->gi);
        for my $a(keys %$atts ) {
            $a =~ s".*/([^/]+)$"$1";
            next unless $record_tag->parent->att($a);
            $par->set_att($a,'');
        }
###z# print 3;
        $elt->set_att('record_tag__','true');
        $elt->paste('first_child',$par);
        $par->paste('before',$record_tag->parent);
#        $record_tag = $self->{record_tag} = $record_tag->parent->prev_sibling->first_child;
        $record_tag ||= $self->{record_tag} = $record_tag->parent->prev_sibling->first_child;
    }
    else {
        for my $a(keys %$atts ) {
            $a =~ s".*/([^/]+)$"$1";
            next unless $record_tag->att($a);
            $elt->set_att($a,'');
        }
###z# print 4;
        $record_tag ||= $self->{record_tag} = $record_tag->prev_sibling;
#        $record_tag = $self->{record_tag} = $record_tag->prev_sibling;
    }
    $record_tag ||= $twig->root->first_child;
    my $old = $record_tag->next_elt($record_tag->gi);
#    $old->delete if $self->{create};
#    $old->set_att('frump','foo') if $old;
    $old->del_att('record_tag__') if $old;
#$twig->print;
    #print "\n"; 
    #$old->print if $old;
    ##print "\n"; 
#    my $par = $self->create_record;
#    $self->{blank_element} = $par;
    #printf "\n%s\n   %s\n", $elt->path, "@$col_names";
    @$col_names = map {s"/#PCDATA""; $_}  @$col_names;
#$twig->print;  print "\n\n";
#use Data::Dumper; print Dumper $record_tag->gi,$col_names,$atts;
    return $record_tag,$col_names,$atts;
}

sub check_twig_options {
    my $flags = shift;
    my $new_flags;
    my %twig_opt = %XML::Twig::valid_option;
    return $flags unless scalar (keys %twig_opt);
    while (my($k,$v) = each %$flags) {
        $new_flags->{$k} = $v if $twig_opt{$k};
    }
    return $new_flags;
}

sub get_structure_from_map {
    my $self = shift;
    my $twig = shift;
    my $col_map = shift;
    my($amap,$map,$multi,$col_names,$pretty_cols,$col2tag);
    for my $col(@$col_map) {
        my($tag_name,$col_name) = ($col,$col);
        ($tag_name,$col_name) = each %$col if ref $col eq 'HASH';
        my($tname,$tparent) = ($tag_name,$tag_name);
        if ($tname =~ m!(.*)/([^/]*)$! ) {
            $tparent = $1;
            $tname   = $2;
            $tparent =~ s!.*/([^/]*)$!$1!;
	}
        my $tag  = $twig->first_elt($tname);
        $tag_name=$tag->path if $tag;
        if (!$tag) {
            my $new_tag  = $twig->first_elt($tparent);
            # die "No such element '$tname'!" unless $tag;
            if (!$new_tag) {
                $tag_name = $tname;
	    }
            else {
                $tag_name=$new_tag->path . '/' . $tname;
            }
            $amap->{$tag_name}++;
	}
        if (ref $col_name eq 'ARRAY') {
	  for my $col2(@$col_name) {
              $col2tag->{$col2} = $tag_name;
              $multi->{$tag_name}++;
              push @$pretty_cols, $col2;
	  }
	}
        push @$col_names, $tag_name;
        push @$pretty_cols, $col_name unless ref $col_name eq 'ARRAY';
        $map->{$tag_name} = $col_name;
    }
    my $record_tag;
    my $record_tag_path = '';
    for my $col(@$col_names) {
        my($rt) = $col =~ m!(.*)/[^/]*$!;
        next unless $rt;
        $record_tag_path = $rt if length $rt > length $record_tag_path;
    }
    my @children = $twig->root->descendants;
    for my $e(@children) {
        next unless $e->path eq $record_tag_path;
        $record_tag = $e;
        last;
    }
    if (!$record_tag) {
       $record_tag = $twig->root->first_child;
       my $p = $record_tag->path;
       @$col_names = map {$p.'/'.$_}@$col_names;
#       use Data::Dumper; print Dumper $amap;
       my $newmap;
       $newmap->{ $p.'/'.$_ }++ for keys %{$amap};
       $amap = $newmap;
       $newmap = {};
       $newmap->{ $p.'/'.$_ } = $map->{$_} for keys %{$map};
       $map = $newmap;
    }
##
#=pod
#paste into parent record_tag__
#    my $rt_atts = $record_tag->atts;
#    if (!$rt_atts->{record_tag__}) {
#       my $new_rt = $record_tag->copy;
#       $new_rt->set_att('record_tag__','1');
#       $new_rt->set_att('xstruct__','1');
#       $new_rt->paste('first_child',$record_tag->parent);
#       $record_tag = $new_rt;
#    }
#=cut
    my $col_structure = {
        amap => $amap,
        map  => $map,
        multi => $multi,
        col_names => $col_names,
        pretty_cols => $pretty_cols,
        col2tag     => $col2tag,
    };
# print $record_tag->path, "\n";
# use Data::Dumper; print Dumper $col_structure; 
# exit;
    return $record_tag, $col_structure;
}

sub get_data {
    my $self = shift;
    my $fh_or_str  = shift;
    my $url = $self->{url};
    if ( $url ) {
      $fh_or_str = AnyData::Storage::RAM::get_remote_data({},$url);
    }
    return if( ! defined( $fh_or_str ) );
    my $col_names = shift || [];
    $col_names = []; #### IGNORE USER COLUMN NAMES FOR NOW
    my $flags;
    while (my($k,$v)=each %$self) {
        $flags->{$k}=$v;
    }
    my $root_tag            = $flags->{root_tag};
    my $depth_limit         = $flags->{depth_limit};
    my $supplied_col_names  = $flags->{col_names};
    my $have_col_names      = 1 if $supplied_col_names;
    my $pretty_col_names    = $supplied_col_names;
    my $col_structure = $self->{col_structure};
    undef $col_structure unless $col_structure->{col_names}
                            and scalar @{$col_structure->{col_names}};
    my %multi;
    my %map;
    my %amap;
    $flags->{LoadDTD} = 1;
    $flags->{TwigRoots} = {$root_tag=>'1'} if $root_tag;
#
# DEFAULTS : KeepEncoding OFF to mirror XML::Twig
#            ProtocolEncoding 'ISO-8859-1'
#
#    $flags->{KeepEncoding}     ||= 1;
#
    $flags->{ProtocolEncoding} ||= 'ISO-8859-1';
#use Data::Dumper; die Dumper $flags;
    $flags = check_twig_options($flags);

    my $twig= new XML::Twig(%{$flags});
    my $success = $twig->safe_parse($fh_or_str);
    $self->{errstr} = $@ unless $success;
    die $self->{errstr} if $self->{errstr};
    return undef unless $success;
    $self->{dtd} = $twig->dtd;
    my $root = $twig->first_elt($root_tag) || $twig->root;
    my $name = $root->path;
    my $element= $twig->root;
    my($record_tag,$colZ,$atts);

    my $col_map = $self->{col_map};
    if ($col_map) {
      ($record_tag,$col_structure) =
          $self->get_structure_from_map($twig,$col_map);
    } 
    else {
      ($record_tag,$colZ,$atts) = $self->get_structure($twig);
      if (!$col_structure) {
          $have_col_names++;
          $col_structure = build_column_names($colZ,$root,$root_tag,$colZ);
          $col_structure->{amap} = $atts;
        }
    }

    # CREATE A DUMMY RECORD TAG
    #
    my $rt_atts = $record_tag->atts;
    if (!$rt_atts->{record_tag__}) {
       my $new_rt = $record_tag->copy;
       $new_rt->set_att('record_tag__','1');
       $new_rt->set_att('xstruct__','1');
       $new_rt->paste('first_child',$record_tag->parent);
       $record_tag = $new_rt;
    }

    # $twig->print;
    # use Data::Dumper; print Dumper $col_structure;
  #  print $self->{record_tag}->path;

    $self->{record_tag}    = $record_tag;
    $self->{twig}          = $twig;
    $self->{col_names}     = $col_structure->{pretty_cols};
    $self->{col_structure} = $col_structure;
    return 1;
}


###############################################################
# MAP A ROW HASH ONTO A COLUMN NAMES ARRAY
###############################################################
sub rowhash_to_array {
    my $row           = shift;
    my $col_structure = shift;
#die Dumper $col_structure;
    my $col_names        = $col_structure->{col_names};
    my %map              = %{ $col_structure->{map} } if $col_structure->{map};
    my %multi            = %{ $col_structure->{multi} } if $col_structure->{multi};
    my $pretty_col_names = $col_structure->{pretty_cols} if $col_structure->{pretty_cols};
    my @newvals;
    my %visited;
    for my $coln(@$col_names) {
 	my $tag = $map{$coln};
        #next unless $tag;
        if (!$multi{$tag}) {
            $row->{$tag} ? push @newvals, $row->{$tag} : push @newvals, undef;
	}
        else {
            if (!$visited{$tag}) {
                $visited{$tag}++;
                my @multi_col = ref $row->{$tag} eq 'ARRAY'
 	                  ? @{$row->{$tag}}
                          : ($row->{$tag});
                push @multi_col,undef unless scalar @multi_col;
	        my $dif = ($multi{$tag}) - (scalar @multi_col);
                push @multi_col,undef for 0 .. $dif;
                push @newvals,$_ for @multi_col;
	    }
        }
    }
    return( \@newvals );
}
###############################################################
# BUILD A COLUMN NAMES LIST IF NONE HAS BEEN BUILT YET
###############################################################
sub build_column_names {
    my $tags = shift;
    my $root = shift;
    my $root_tag = shift;
    my $col_names = shift || [];
    my %multi;
    my %map;
    for my $col(@$col_names) {
        $multi{$col}++;
    }
    my %num;
    my $newcolz;
    for my $col(@$col_names) {
      if ($multi{$col} <2) {
          push @$newcolz, $col;
          $map{$col}=$col;
          next;
      } 
      $num{$col}++;
      push @$newcolz, $col.$num{$col};
      $map{$col.$num{$col}}=$col;
    }
    $col_names = $newcolz;
    # REMOVE AS MUCH OF THE PATH AS POSS., KEEPING NAMES UNIQUE
    #
    my $prefix = $root->gi;
    $prefix .= "/$root_tag" if $root_tag;
    my $pretty_col_names;
    die "No Column Names!" unless$col_names;
    @$pretty_col_names = @$col_names;
    @$pretty_col_names = map {$_ =~ s"^/$prefix/"";$_} @$pretty_col_names;
    my %is_member;
    my @newcols;
    for my $col(@$pretty_col_names) {
        my $newc = $col;
        $newc =~ s".*/([^/]*)$"$1";
        if ($is_member{$newc}) {
            $newc = $col;
            $newc =~ s"[^/]*/(.*)"$1";
   	}
        push @newcols, $is_member{$newc} ? $col : $newc;
        $is_member{$newc}=1;
    }
    @$pretty_col_names = @newcols;
    @$pretty_col_names = map {s"/"_"g;$_} @$pretty_col_names;
    for (keys %multi) {
        $multi{$_} = $multi{$_} -1;
        delete $multi{$_} unless $multi{$_};
    }
    my $col_structure = {
        col_names   => $col_names,
        map         => \%map,
        multi       => \%multi,
        pretty_cols => $pretty_col_names,
    };
    #print Dumper $col_structure;
    return( $col_structure );
}
###############################################################

sub export {
    my $self = shift;
    my $storage = shift;
#z  my $format = shift;
    my $file = shift;
    my $flags = shift || {};
#$self->{twig}->print;
    if ( 
      ( $storage and $file and !$storage->{fh} )
       ) {
       $storage->{file_name} = $file;
       $storage->{fh} = $storage->open_local_file($file,'o');
    }
    return unless $self->{twig};
#$self->{twig}->print;
    $self->{twig}->set_pretty_print($flags->{pretty_print}) if $flags->{pretty_print};
    #$self->{twig}->print; print "\n\n";
    #$self->{twig}->finish_print;
    my $fh  = $storage->{fh} if $storage;
    my $r = $self->{twig}->root->gi;
    my $str = $self->{outside_of_tree} || '';
    my $rectag = $self->{record_tag};
#    $self->{twig}->first_elt($self->{record_tag}->gi)->delete;
    my $elt= $self->{twig}->root;
# $self->{destroy}= 1;
#print "FOO";
    if ( $self->{destroy}) {
        for my $e($elt->descendants) {
            if ( $e->att('xstruct__') ) {
                $e->del_att('xstruct__');
#                next unless defined $e->next_elt($e->gi);
               $e->delete;
                #next;
            }
	}
    }
    $elt= $self->{twig}->root;
    while( $elt= $elt->next_elt ){
        #for (keys %{$elt->atts}) { print "$_#"; }
        my $del_parent;
#        $elt->delete if $elt->text =~ /x/ and $elt->is_text;
        if ($elt->children == 0 ) {
 #          $elt->delete;
           next;
        } 
        next if !$elt->att('record_tag__'); 
        for ($elt->children) {
           $_->delete;
	}
        if ($elt->parent and $elt->parent->children < 2) {
           $del_parent++;
        } 
        $elt->parent->delete if $del_parent;
        $elt->delete;
    }
###z
#  $str = defined $fh ? $self->{twig}->print($fh)
#                       : $self->{twig}->sprint();
  if($file and defined $fh ){ $str = $self->{twig}->print($fh) }
  else {$str = $self->{twig}->sprint();}
    undef $storage->{fh};
    return $str;
}

1;

=head1 NAME

 AnyData::Format::XML - tiedhash and DBI access to XML

=head1 SYNOPSIS

 # access XML data via a multidimensional tied hash
 # see AnyData.pod for full details
 #
 use AnyData;
 my $table = adTie( 'XML', $file, $mode, $flags );

 OR

 # convert data to and from XML
 # see AnyData.pod for full details
 #
 use AnyData;
 adConvert( 'XML', $file1, $any_other_format, $file2, $flags );
 adConvert( $any_other_format, $file1, 'XML', $file2, $flags );

 OR

 # access the data via DBI and SQL
 # see DBD::AnyData.pod for full details
 #
 use DBI;
 my $dbh = DBI->connect( 'dbi:AnyData' );
 $dbh->func('mytable','XML',$file,$flags,'ad_catalog');

See below for a description of the optional flags that apply
to all of these examples.

=head1 DESCRIPTION

This module allows you to create, search, modify and/or convert XML data
and files by treating them as databases without having to actually
create separate database files.  The data can 
be accessed via a multidimensional tiedhash using AnyData.pm or via DBI 
and SQL commands using DBD::AnyData.pm.  See those modules for 
complete details of usage.

The module is built on top of Michel Rodriguez's excellent XML::Twig which
means that the AnyData interfaces can now include information from DTDs,
be smarter about inferring data structure, reduce memory consumption on
huge files, and provide access to many powerful features of XML::Twig and
XML::Parser on which it is based.

Importing options allow you to import/access/modify XML of almost any length or complexity.  This includes the ability to access different subtrees as separate or joined databases.

Exporting and converting options allow you to take data from almost any source (a perl array, any DBI database, etc.) and output it as an XML file.  You can control the formatting of the resulting XML either by supplying a DTD listing things like nesting of tags and which columns should be output as attributes and/or you can use XML::Twig pretty_print settings to generate half a dozen different levels of compactness or whitespace in how the XML looks.

The documentation below outlines the special flags that can be used
in either of the interfaces to fine-tune how the XML is treated.

The flags listed below define the relationship between tags and 
attributes in the XML document and columns in the resulting database.
In many cases, you can simply accept the defaults and the database
will be built automatically.  However, you can also fine tune the
generation of the database by specifying which tags and attributes
you are interested in and their relationship with database columns.

=head1 USAGE

=head2 Prerequisites

To use the tied hash interface, you will need 

 AnyData
 XML::Twig
 XML::Parser

To use the DBI/SQL interface, you will need those, and also

 DBI
 DBD::AnyData

=head2 Required flags ( none )

If no flags are specified, then the module determines the database
structure from examining the file or data itself, making use of the DTD if there is one, otherwise scanning the first child of the XML tree for structural information.

=head2 Optional flags

 If the default behavior is not sufficient, you may either specify a
 "record_tag" which will be used to define column names, or you can define an
 entire tag-to-column mapping.


For simple XML, no flags are necessary:

 <table>
    <row row_id="1"><name>Joe</name><location>Seattle</location></row>
    <row row_id="2"><name>Sue</name><location>Portland</location></row>
 </table>

The record_tag will default to the first child, namely "row".  The column
names will be generated from the attributes of the record tag and all of
the tags included under the record tag, so the column names in this
example will be "row_id","name","location".

If the record_tag is not the first child, you will need to specify it.  For example:

 <db>
   <table table_id="1">
     <row row_id="1"><name>Joe</name><location>Seattle</location></row>
     <row row_id="2"><name>Sue</name><location>Portland</location></row>
   </table>
   <table table_id="2">
     <row row_id="1"><name>Bob</name><location>Boise</location></row>
     <row row_id="2"><name>Bev</name><location>Billings</location></row>
   </table>
 </db>

In this case you will need to specify "row" as the record_tag since it is not the first child of the tree.  The column names will be generated from the attributes of row's parent (if the parent is not the root), from row's attributes
and sub tags, i.e. "table_id","row_id","name","location".

In some cases you will need to specify an entire tag-to-column mapping.  For example, if you want to use a different name for the database column than is used in the XML (especially if the XML tag is not a valid SQL column name).  You'd also need to specify a mapping if there are two tags with the same name in different places in the XML tree.

The column mapping is a reference to an array of column definitions.  A column definition is either a simple name of a tag, or a hash reference with the key containing the full path of the XML tag and the value containing the desired column name alias.

For example:

  col_map => [ 'part_id', 'part_name', 'availability' ];

That will find the first three tags with those names and create the database using the same names for the tags.

Or:

  col_map => [
               { '/parts/shop/id'        => 'shop_id'},
               { '/parts/shop/part/id'   => 'part_id'},
               { '/parts/shop/part/name' => 'part_name'},
             ];

That would find the three tags referenced on the left and create a database with the three column names referenced on the right.

When exporting XML, you can specify a DTD to control the output.  For example, if you import a table from CSV or from an Array, you can output as XML and specify which of the columns become tags and which become attributes and also specify the nesting of the tags in your DTD.

The XML format parser is built on top of Michel Rodriguez's excellent XML::Twig which is itself based on XML::Parser.  Parameters to either of those modules may be passed in the flags for adTie() and the other commands including the "prettyPrint" flag to specify how the output XML is displayed and things like ProtocolEncoding.  ProtocolEncoding defaults to 'ISO-8859-1', all other flags keep the defaults of XML::Twig and XML::Parser.  See the documentation of those modules for details;

 CAUTION: Unlike other formats, the XML format does not save changes to
 the file as they are entered, but only saves the changes when you explicitly
 request them to be saved with the adExport() command.

=head1 AUTHOR & COPYRIGHT

copyright 2000, Jeff Zucker <jeff@vpservices.com>
all rights reserved

=cut
