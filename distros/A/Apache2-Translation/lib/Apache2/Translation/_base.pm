package Apache2::Translation::_base;

use 5.008008;
use strict;
use warnings;
no warnings qw(uninitialized);

our $VERSION = '0.03';

use constant {
  BLOCK   => 0, 		# \
  ORDER   => 1, 		#  |
  ACTION  => 2,			#  |
  ID      => 3,			#   \ used for internal
  KEY     => 4,			#   / storage
  URI     => 5,			#  |
  NOTE    => 6,			# /

  nKEY    => 0,			# \
  nURI    => 1,			#  |
  nBLOCK  => 2,			#   \ used when updating an element or
  nORDER  => 3,			#   / inserting a new one as $new
  nACTION => 4,			#  |
  nNOTE   => 5,			#  |
  nID     => 6,			# /  # only used in iterator

  oKEY    => 0,			# \
  oURI    => 1,			#  |
  oBLOCK  => 2,			#   \ used when updating an element or
  oORDER  => 3,			#   / deleting one as $old
  oID     => 4,			#  /
};

sub import {
  my $mod=caller;
  no strict 'refs';
  *{$mod."::KEY"}    = \&KEY;
  *{$mod."::URI"}    = \&URI;
  *{$mod."::BLOCK"}  = \&BLOCK;
  *{$mod."::ORDER"}  = \&ORDER;
  *{$mod."::ACTION"} = \&ACTION;
  *{$mod."::NOTE"}   = \&NOTE;
  *{$mod."::ID"}     = \&ID;

  *{$mod."::nKEY"}    = \&nKEY;
  *{$mod."::nURI"}    = \&nURI;
  *{$mod."::nBLOCK"}  = \&nBLOCK;
  *{$mod."::nORDER"}  = \&nORDER;
  *{$mod."::nACTION"} = \&nACTION;
  *{$mod."::nNOTE"}   = \&nNOTE;
  *{$mod."::nID"}     = \&nID;

  *{$mod."::oKEY"}    = \&oKEY;
  *{$mod."::oURI"}    = \&oURI;
  *{$mod."::oBLOCK"}  = \&oBLOCK;
  *{$mod."::oORDER"}  = \&oORDER;
  *{$mod."::oID"}     = \&oID;
}

sub append {
  my ($I, $other, %options)=@_;

  my $drop=$options{drop_notes};
  my $rc=0;
  my $iterator=$other->iterator;
  while( my $el=$iterator->() ) {
    $#{$el}=nACTION if( $drop ); # drop NOTE and ID
    $rc+=$I->insert($el);
  }
  return $rc;
}

sub _expand {
  my ($el, $prefix, $what)=@_;

  my $val=$el->[eval "n$what"];
  while( $prefix=~/(p|s)(.*?);/g ) {
    my ($op, $arg)=($1, $2);
    if( $op eq 'p' ) {
      $val=~s/\s*\z//;
      if( defined $arg ) {
	$val=~s/\r?\n/\n$arg/g;
	substr( $val, 0, 0 )=$arg;
      } else {
	$val=~s/\r?\n//g;
      }
    } elsif( $op eq 's' ) {
      if( $arg eq 'l' ) {
	$val=~s/\A\s*//;
      } else {
	$val=~s/\s*\z//;
      }
    }
  }
  return $val;
}

my $default_fmt=<<'EOF';
######################################################################
%{KEY} & %{URI} %{BLOCK}/%{ORDER}/%{ID}
%{paction> ;ACTION}
%{pnote> ;NOTE}
EOF

sub dump {
  my ($I, $fmt, $fh)=@_;

  $fmt=$default_fmt unless( length $fmt );
  $fh=\*STDOUT unless( ref($fh) );
  my $iterator=$I->iterator;
  while( my $el=$iterator->() ) {
    my $x=$fmt;
    $x=~s/%{(.*?)(KEY|URI|BLOCK|ORDER|ACTION|NOTE|ID)}/_expand($el,$1,$2)/gse;
    print $fh $x;
  }
}

{
  my $_init;
  my $init=sub {
    my ($I, $other, %o)=@_;
    unless($_init) {
      # This is expected to be seldom used. So, don't rely on the
      # existence of these modules.
      die "Please install JSON::XS" unless eval "require JSON::XS";
      die "Please install Algorithm::Diff"
	unless eval "require Algorithm::Diff";
      $_init=1;
    }

    my (@my_stuff, @other_stuff);
    if( exists $o{key} and exists $o{uri} ) {
      my ($key, $uri)=@o{qw/key uri/};
      for( my $it=$I->iterator; my $el=$it->(); ) {
	$#{$el}=nNOTE;		# drop ID
	$el->[nBLOCK]+=0;	# convert to numbers because JSON::XS
	$el->[nORDER]+=0;	# shows 0 as 0 but '0' as "0"
	push @my_stuff, $el if( (ref($key)
				 ? $el->[nKEY] =~ $key
				 : $el->[nKEY] eq $key) and
				(ref($uri)
				 ? $el->[nURI] =~ $uri
				 : $el->[nURI] eq $uri) );
      }
      for( my $it=$other->iterator; my $el=$it->(); ) {
	$#{$el}=nNOTE;		# drop ID
	$el->[nBLOCK]+=0;	# convert to numbers because JSON::XS
	$el->[nORDER]+=0;	# shows 0 as 0 but '0' as "0"
	push @other_stuff, $el if( (ref($key)
				    ? $el->[nKEY] =~ $key
				    : $el->[nKEY] eq $key) and
				   (ref($uri)
				    ? $el->[nURI] =~ $uri
				    : $el->[nURI] eq $uri) );
      }
    } elsif( exists $o{key} ) {
      my $key=$o{key};
      for( my $it=$I->iterator; my $el=$it->(); ) {
	$#{$el}=nNOTE;		# drop ID
	$el->[nBLOCK]+=0;	# convert to numbers because JSON::XS
	$el->[nORDER]+=0;	# shows 0 as 0 but '0' as "0"
	push @my_stuff, $el if( ref($key)
				? $el->[nKEY] =~ $key
				: $el->[nKEY] eq $key );
      }
      for( my $it=$other->iterator; my $el=$it->(); ) {
	$#{$el}=nNOTE;		# drop ID
	$el->[nBLOCK]+=0;	# convert to numbers because JSON::XS
	$el->[nORDER]+=0;	# shows 0 as 0 but '0' as "0"
	push @other_stuff, $el if( ref($key)
				   ? $el->[nKEY] =~ $key
				   : $el->[nKEY] eq $key );
      }
    } elsif( exists $o{uri} ) {
      my $uri=$o{uri};
      for( my $it=$I->iterator; my $el=$it->(); ) {
	$#{$el}=nNOTE;		# drop ID
	$el->[nBLOCK]+=0;	# convert to numbers because JSON::XS
	$el->[nORDER]+=0;	# shows 0 as 0 but '0' as "0"
	push @my_stuff, $el if( ref($uri)
				? $el->[nURI] =~ $uri
				: $el->[nURI] eq $uri );
      }
      for( my $it=$other->iterator; my $el=$it->(); ) {
	$#{$el}=nNOTE;		# drop ID
	$el->[nBLOCK]+=0;	# convert to numbers because JSON::XS
	$el->[nORDER]+=0;	# shows 0 as 0 but '0' as "0"
	push @other_stuff, $el if( ref($uri)
				   ? $el->[nURI] =~ $uri
				   : $el->[nURI] eq $uri );
      }
    } else {
      for( my $it=$I->iterator; my $el=$it->(); ) {
	$#{$el}=nNOTE;		# drop ID
	$el->[nBLOCK]+=0;	# convert to numbers because JSON::XS
	$el->[nORDER]+=0;	# shows 0 as 0 but '0' as "0"
	push @my_stuff, $el;
      }
      for( my $it=$other->iterator; my $el=$it->(); ) {
	$#{$el}=nNOTE;		# drop ID
	$el->[nBLOCK]+=0;	# convert to numbers because JSON::XS
	$el->[nORDER]+=0;	# shows 0 as 0 but '0' as "0"
	push @other_stuff, $el;
      }
    }

    my $serializer=\&JSON::XS::encode_json;
    if( exists $o{notes} and !$o{notes} ) {
      my $f=$serializer;
      $serializer=sub { my @el=@{$_[0]}; $el[nNOTE]=''; $f->(\@el) };
    }
    if( exists $o{numbers} and !$o{numbers} ) {
      my $f=$serializer;
      $serializer=sub { my @el=@{$_[0]}; @el[nBLOCK,nORDER]=(0,0); $f->(\@el) };
    }

    return (\@my_stuff, \@other_stuff, $serializer);
  };
  sub diff  {Algorithm::Diff::diff($init->(@_));}
  sub sdiff {Algorithm::Diff::sdiff($init->(@_));}
}

sub DESTROY {}

1;
__END__
