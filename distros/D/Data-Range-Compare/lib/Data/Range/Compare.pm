package Data::Range::Compare;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use overload '""'=>\&notation ,fallback=>1;

require Exporter;
$VERSION='1.031';

@ISA=qw(Exporter);

use constant key_helper    => 0;
use constant key_start     => 1;
use constant key_end       => 2;
use constant key_generated => 3;
use constant key_missing   => 4;
use constant key_data      => 5;

@EXPORT_OK=qw(
  key_helper
  key_start
  key_end
  key_generated
  key_missing
  key_data

  add_one 
  sub_one 
  cmp_values

  sort_largest_range_end_first
  sort_largest_range_start_first
  sort_smallest_range_start_first
  sort_smallest_range_end_first
  sort_in_consolidate_order
  sort_in_presentation_order

  HELPER_CB
);

%EXPORT_TAGS=(
  KEYS=>[qw(
 	  key_helper
          key_start
          key_end
          key_generated
          key_missing
          key_data
  )]

  ,ALL=>\@EXPORT_OK

  ,HELPER_CB=>[qw(HELPER_CB)]
  ,HELPER=>[qw(add_one sub_one cmp_values)]
  ,SORT=>[qw(
    sort_largest_range_end_first
    sort_largest_range_start_first
    sort_smallest_range_start_first
    sort_smallest_range_end_first
    sort_in_consolidate_order
    sort_in_presentation_order
   )]
);

sub new {
  my $s=shift @_;
  bless [@_],$s;
}

sub helper_cb { my ($s,$key,@args)=@_; $s->[key_helper]->{$key}->(@args) }

sub range_start () { $_[0]->[key_start] }
sub range_end () { $_[0]->[key_end] }

sub notation { 
  my $notation=join ' - ',$_[0]->range_start,$_[0]->range_end;
  $notation;
}
sub helper_hash () { $_[0]->[key_helper] }
sub missing () {$_[0]->[key_missing] }
sub generated () {$_[0]->[key_generated] }

sub data () {
  my ($s)=@_;
  return $s->[key_data] if ref($s->[key_data]);
  $s->[key_data]={};
  $s->[key_data]
}

sub overlap ($) {
  my ($range_a,$range_b)=@_;
  return 1 if 
      $range_a->cmp_range_start($range_b)!=1
        &&
      $range_a->cmp_range_end($range_b)!=-1;
  return 1 if 
      $range_a->helper_cb(
        'cmp_values'
	,$range_a->range_start
	,$range_b->range_end 
      )!=1
        &&
      $range_a->helper_cb(
        'cmp_values'
	,$range_a->range_end
	,$range_b->range_end
      )!=-1;

  return 1 if 
      $range_b->cmp_range_start($range_a)!=1
        &&
      $range_b->cmp_range_end($range_a)!=-1;

  return 1 if 
      #$range_b->range_start <=$range_a->range_end 
      $range_a->helper_cb(
        'cmp_values'
	,$range_b->range_start
	,$range_a->range_end
      )!=1
        &&
      $range_a->helper_cb(
        'cmp_values'
	,$range_b->range_end
	,$range_a->range_end
      )!=-1;

  undef
}

sub grep_overlap ($) { [ grep {$_[0]->overlap($_) } @{$_[1]} ] }
sub grep_nonoverlap ($) { [ grep { $_[0]->overlap($_) ? 0 : 1 } @{$_[1]} ] }

sub contains_value ($) {
  my ($s,$cmp)=@_;
  return 0 if $s->helper_cb('cmp_values',$s->range_start,$cmp)==1;
  return 0 if $s->helper_cb('cmp_values',$cmp,$s->range_end)==1;
  1
}

sub next_range_start () { $_[0]->helper_cb('add_one',$_[0]->range_end)  }
sub previous_range_end () { $_[0]->helper_cb('sub_one',$_[0]->range_start)  }

sub cmp_range_start($) {
  my ($s,$cmp)=@_;
  $s->helper_cb('cmp_values',$s->range_start,$cmp->range_start)
}

sub cmp_range_end($) {
  my ($s,$cmp)=@_;
  $s->helper_cb('cmp_values',$s->range_end,$cmp->range_end)
}

sub contiguous_check ($) {
  my ($cmp_a,$cmp_b)=@_;
  $cmp_a->helper_cb(
   'cmp_values'
   ,$cmp_a->next_range_start
   ,$cmp_b->range_start
  )==0
}

sub cmp_ranges ($) {
  my ($range_a,$range_b)=@_;
  my $cmp=$range_a->cmp_range_start($range_b);
  if($cmp==0) {
    return $range_a->cmp_range_end($range_b);
  }
  return $cmp;
}

sub HELPER_CB () {
  add_one=>\&add_one
  ,sub_one=>\&sub_one
  ,cmp_values=>\&cmp_values
}

sub add_one { $_[0] + 1 }
sub sub_one { $_[0] -1 }
sub cmp_values { $_[0] <=> $_[1] }

sub get_common_range {
  my ($class,$helper,$ranges)=@_;

  my ($range_start)=sort sort_largest_range_start_first @$ranges;
  my ($range_end)=sort sort_smallest_range_end_first @$ranges;

  new($class,
    $helper
    ,$range_start->range_start
    ,$range_end->range_end
  );
}

sub get_overlapping_range {
  my ($class,$helper,$ranges,%opt)=@_;

  my ($range_start)=sort sort_smallest_range_start_first @$ranges;
  my ($range_end)=sort sort_largest_range_end_first @$ranges;

  my $obj=new($class,$helper,$range_start->range_start,$range_end->range_end);
  $obj->[key_generated]=1;
  $obj;
}

sub sort_in_presentation_order ($$) {
	my ($cmp_a,$cmp_b)=@_;
	$cmp_a->cmp_ranges($cmp_b);
}

sub sort_in_consolidate_order ($$) {
  my ($range_a,$range_b)=@_;
  $range_a->cmp_range_start($range_b)
    ||
  $range_b->cmp_range_end($range_a);
}

sub sort_largest_range_end_first ($$) {
  my ($range_a,$range_b)=@_;
  $range_b->cmp_range_end($range_a)
}

sub sort_smallest_range_start_first ($$) {
  my ($range_a,$range_b)=@_;
  $range_a->cmp_range_start($range_b)
}

sub sort_smallest_range_end_first ($$) {
  my ($range_a,$range_b)=@_;
  $range_a->cmp_range_end($range_b)
  
}

sub sort_largest_range_start_first ($$) {
  my ($range_a,$range_b)=@_;
  $range_b->cmp_range_start($range_a)
}

sub consolidate_ranges {
  my ($class,$helper,$ranges,%opt)=@_;
  @$ranges=sort sort_in_consolidate_order @$ranges;
  my $cmp=shift @$ranges;
  my $return_ref=[];
  while( my $next=shift @$ranges) {
    if($cmp->overlap($next)) {
      my $overlap=$cmp->cmp_ranges($next)==0 ? 
        $cmp
	:
        $class->get_overlapping_range($helper,[$cmp,$next]);
      $cmp=$overlap;

    } else {
      push @$return_ref,$cmp;
      $cmp=$next;
    }
  
  }
  push @$return_ref,$cmp;
  $return_ref;
}

sub fill_missing_ranges {
  my ($class,$helper,$ranges,%args)=@_;
  %args=(consolidate_ranges=>0,%args);

  $ranges=consolidate_ranges($helper,$ranges) if $args{consolidate_ranges};
  my $return_ref=[];

  my $cmp=shift @$ranges;
  while(my $next=shift @$ranges) {
    push @$return_ref,$cmp;
    unless($cmp->contiguous_check($next)) {
      my $missing=new($class,
        $helper
        ,$cmp->next_range_start
        ,$next->previous_range_end);
      $missing->[key_missing]=1;
      push @$return_ref,$missing;
    }
    $cmp=$next;
  }

  push @$return_ref,$cmp;

  $return_ref;
}

sub range_start_end_fill {
  my ($class,$helper,$ranges,%opt)=@_;

  my ($range_start)=sort sort_smallest_range_start_first
    map { $_->[0] } @$ranges;
    $range_start=$range_start->range_start;
  my ($range_end)=sort sort_largest_range_end_first
    map { $_->[$#{$_}] } @$ranges;
    $range_end=$range_end->range_end;
  
  foreach my $ref (@$ranges) {
    my $first_range=$ref->[0];
    my $last_range=$ref->[$#{$ref}];

    if($first_range->helper_cb(
      'cmp_values'
      ,$first_range->range_start
      ,$range_start
      )!=0) {
      my $new_range=new($class,
          $helper
          ,$range_start
          ,$first_range->previous_range_end
      );
      unshift @$ref,$new_range;
      $new_range->[key_missing]=1;
      $new_range->[key_generated]=1;
    }

    if($last_range->helper_cb('cmp_values'
       ,$last_range->range_end
       ,$range_end)!=0
    ) {
      my $new_range=new($class,
        $helper
        ,$last_range->next_range_start
        ,$range_end
      );
      push @$ref,$new_range;
      $new_range->[key_missing]=1;
      $new_range->[key_generated]=1;
    }
  }


  $ranges;
}

sub range_compare {
  my ($class,$helper,$list_of_ranges,%args)=@_;

  %args=(consolidate_ranges=>1,%args);

  if($args{consolidate_ranges}) {
    my $ref=[];
    while(my $ranges=shift @$list_of_ranges) {
      $ranges=$class->consolidate_ranges($helper,$ranges);
      push @$ref,$ranges;
    }
    $list_of_ranges=$ref;
  }
  my ($row,$column_ids);
  my $next=1;
  sub {
    return () unless $next;
    if($column_ids) {
      ($row,$column_ids,$next)=$class->compare_row(
        $helper
        ,$list_of_ranges
        ,$row,$column_ids
      );
    } else {
      ($row,$column_ids,$next)=$class->init_compare_row(
        $helper
        ,$list_of_ranges
      );
    }
    @$row;
  };
}

sub init_compare_row {
  my ($class,$helper,$data)=@_;

  my $next=0;
  my $cols=[];
  my $row=[];

  my @list=map { $_->[0] } @$data;
  my ($first)=sort sort_smallest_range_start_first @list;

  for(my $id=0;$id<=$#$data;++$id) {
    my $range=$data->[$id]->[0];
    if($range->cmp_range_start($first)==0) {
      push @$row,$range;
      $cols->[$id]=0;
      ++$next if $#{$data->[$id]}>0;
    } else {
      $cols->[$id]=-1;
      push @$row,new($class,
        $helper
        ,$first->range_start
        ,$range->previous_range_end
        ,1
        ,1
      );
      ++$next;
    }
  }
  return $row,$cols,$next;
}

sub compare_row {
  my ($class,$helper,$data,$row,$cols)=@_;

  # if we don't have our column list then we need to build it
  my ($last)=sort sort_smallest_range_end_first @$row;
  my ($end)=sort sort_largest_range_end_first 
    map { $_->[$#$_] } @$data;

  my $total=1 + ($#$data);
  my $ok=$total;
  my $missing_count=0;
  for(my $id=0;$id<=$#$data;++$id) {
    my $range=$row->[$id];

    my $current=$cols->[$id];
    my $next=1 + $current;
    if($#{$data->[$id]} < $next) {
    	$next=undef;
    }
     
    if($last->cmp_range_end($range)==0) {
      if(defined($next)) {
       my $next_range=$data->[$id]->[$next];

       if($range->contiguous_check($next_range)) {
        $cols->[$id]=$next;
	$row->[$id]=$next_range;
       } else {
        $row->[$id]=new($class,
	  $helper
	  ,$range->next_range_start
	  ,$next_range->previous_range_end
	  ,1
	  ,1
	 );
       }
      } else {
	$row->[$id]=new($class,
	 $helper
	 ,$range->next_range_start
	 ,$end->range_end
	 ,1
	 ,1
        );
      }
    }
    ++$missing_count if $row->[$id]->missing;
    --$ok if $row->[$id]->cmp_range_end($end)>=0;
  }
  return $class->compare_row($helper,$data,$row,$cols) 
      if $ok and $missing_count==$total;
  ($row,$cols,$ok)
}

1;
