package Data::JPack;
use strict;
use warnings;
use feature ":all";

our $VERSION="v0.2.1";

use feature qw<say>;
no warnings "experimental";

use MIME::Base64;
use IO::Compress::RawDeflate qw<rawdeflate>;
use IO::Uncompress::RawInflate qw<rawinflate $RawInflateError>;

use File::Basename qw<basename dirname>;

use constant::more B64_BLOCK_SIZE=>(57*71); #Best fit into page size

use File::Path qw<make_path remove_tree>;

use File::ShareDir ":ALL";
my $share_dir=dist_dir "Data-JPack";

use Export::These qw<jpack_encode jpack_encode_file jpack_decode_file>;

# turn any data into locally (serverless) loadable data for html/javascript apps

#represents a chunk of a data to load
#could be a an entire file, or just part of one
#
use constant::more('options_=0', qw<compress_ buffer_ src_ html_root_ html_container_ prefix_  current_set_ current_file_>);

# Database of files seen by a html_container.
#
my %seen;




sub new {
	my $pack=shift//__PACKAGE__;
	#options include
	#	compression
	#	tagName
	#	chunkSeq
	#	relativePath
	#	type
	#
	my $self=[];
	my %options=@_;
	$self->[options_]=\%options;;

	$self->[options_]{jpack_type}//="data";
	$self->[options_]{jpack_compression}//="none";
	$self->[options_]{jpack_seq}//=0;
  $self->[buffer_]="";
  $self->[options_]{html_container}//="index.html";
  #$self->[options]{prefix}";
  
  
  for($self->[options_]{html_container}){
    if(/\.html$/){
      # If it looks like a html file, then assume it will be
      $self->[html_root_]=dirname $_;
    }
    elsif( -d or ! -x){
      # If its a existing or non existing location assume a dir
      $self->[html_root_]=$_;
    }
    else {
      $self->[html_root_]=dirname $_;
    }
  }

  make_path $self->[html_root_];

  #$self->[prefix_]
  #$self->[html_root_];
	bless $self , $pack;
}

sub encode_header {
	my $self=shift;
	for ($self->[options_]{jpack_compression}){
		if(/deflate/i){
			my %opts;
			my $deflate=IO::Compress::RawDeflate->new(\$self->[buffer_]);

			$self->[compress_]=$deflate;
		}
    else{
		}
	}

  # NOTE: Technically this isn't needed as the RawDefalte does not add the zlib
  # header. However if Deflate is used then this wipes out the header
  #
  $self->[buffer_]="";

	my $header=""; 
	my $options=($self->[options_]);
	if($self->[options_]{embedded}){
		$header.= ""
		. qq|<script defer type="text/javascript" onload="chunkLoaded(this)" |
		. join('', map {qq|$_="|.$options->{$_}.qq|" |} keys %$options)
		. ($self->[options_]{src}? qq|src="|.$self->[options_]{src}.qq|" >\n| : ">\n")
		;
	}

	$header.=""
  #. qq|console.log(document.currentScript);|
		. qq|chunkLoader.decodeData({jpack_path:document.currentScript.src,|
		. join(", ", map {qq|$_:"|.$options->{$_}.qq|"|} keys %$options)
		. qq|}, function(){ return "|;
		;
}

sub encode_footer {
	#force a flush
	my $self=shift;

  # flush internal buffer
  $self->[compress_]->flush() if $self->[compress_];
  # Encode the rest of the the data
  my $rem=encode_base64($self->[buffer_], "" );

	my $footer= $rem .qq|"\n});\n|;


	if($self->[options_]{embedded}){
		$footer.=qq|</script>|;
	}
	$footer;
}

sub encode_data {
	my $self=shift;
  my $data=shift;
  my $out="";
	if($self->[compress_]){
		$self->[compress_]->write($data);
	}
	else {
    # Data might not be correct size for base64 so append
		$self->[buffer_].=$data;
	}
	
  my $multiple=int(length ($self->[buffer_])/B64_BLOCK_SIZE);
  #
  #
  if($multiple){
    # only convert block if data is correcty multiple
   $out=encode_base64(substr($self->[buffer_], 0, $multiple*B64_BLOCK_SIZE,""),"");
  }
  $out;
}


# Single shot data encoding. Adds a header, data and footer
#
sub encode {
  my $self=shift;
  my $data=shift;

	$self->encode_header
	.$self->encode_data($data)
	.$self->encode_footer
}
 
sub encode_file {
  my $self=shift;

	my $path = shift;
  my $out_path=shift;

	local $/;
  #return unless 
  open my $file, "<", $path or die "$path: $!";

	my $data=$self->encode(<$file>);

  if($out_path){
    my $dir=dirname $out_path;
    make_path $dir;
    open my $fh, ">", $out_path or die $!;
    print $fh $data;
  }
  else
  {
    $data;
  }

}

#single shot.. non OO
sub jpack_encode {
	my $data=shift;
	my $jpack=Data::JPack->new(@_);

	$jpack->encode($data);
}


# Opens, reads and encodes data from file at $path
# if $out_path is given the dir and file is create and data written
# otherwise the encoded data is returned
sub jpack_encode_file {
	local $/;
	my $path = shift;
  my $out_path=shift;
	return unless open my $file, "<", $path;

	my $data=jpack_encode <$file>, @_;
  if($out_path){
    my $dir=dirname $out_path;
    make_path $dir;
    open my $fh, ">", $out_path;
    print $fh $data;
  }
  else
  {
    $data;
  }

}

sub decode {
  my $self=shift;
  my $data=shift;
  my $compression; 
  $data=~/decodeData\(\s*\{(.*)\}\s*,\s*function\(\)\{\s*return\s*"(.*)"\s*\}\)/;
  my $js=$1;
  $data=$2;
  my @items=split /\s*,\s*/, $js;
  my %pairs= map {s/^\s+//; s/\s+$//;$_ }
          map {split ":", $_} @items;
  for(keys %pairs){
    if(/compression/){
      $pairs{$_}=~/"(.*)"/;
      $compression=$1;
    }
  }

  my $decoded;
  my $output="";
  for($compression){
    if(/deflate/){
      $decoded=decode_base64($data);
      rawinflate(\$decoded, \$output) or die $RawInflateError;
    }
    else {
      $output=decode_base64($data);
    }
  }
  $output;

}

sub jpack_decode {

}

sub jpack_decode_file {
	local $/;
	my $path=shift;
	return unless open my $file,"<", $path;
	my $data=<$file>;

  my $jpack=Data::JPack->new;
  $jpack->decode($data);
}


# File system database
#
# Returns the current set name (dir) for the root dir/prefix
sub next_set_name {
  my $self=shift;
  my $force=shift;
  # use the html_container as and prefix to locate the current set
  my $dir=join "/", $self->[html_root_], $self->[prefix_]?$self->[prefix_]:();

  my @list;
  if(defined($force)  and $force){
    #my $n= sprintf "%032x", int($force)-1;
    
    push @list, int($force)-1;
  }
  else {
    # List all dirs with the correct formating in the name
    @list= map {hex} sort grep {length == 32 } map {-d; basename $_ } <$dir/*>;

    unless(@list){
      # create a new dir
      #my $name=sprintf "$dir/%032x", 1;
      push @list, -1; #$name;
    }
  }

  my $max=pop @list;

	my $name=sprintf "$dir/%032x", $max+1;

  #make_path $name;

  $self->[current_set_]=$name;
  return $name;
}


# Returns the path of a file, in a next set ( or set provided)
sub next_file_name{
	my $self =shift;
  my $path =shift;

  #Check if the passed file dis defined. If so then we check if its seen or not
  if(defined $path){
    my $p=$self->[html_root_]."/".$self->[prefix_]."/".$path;
    if($seen{$p}){
      #use feature ":all";
      #sleep 1;
      return undef;
    }
    else {
      $seen{$p}=1;
    }
  }
  else {
    # Ass previous versions
  }
  my $set_dir=$self->[current_set_]//$self->next_set_name;

  my @list= map {hex} sort grep {length == 32 } map {s/\.jpack// ; basename $_ } <$set_dir/*.jpack>;

  unless(@list){
    push @list, -1;
  }

  my $max=pop @list;

	my $name=sprintf "$set_dir/%032x.jpack", $max+1;
  return $name;
}

#########################################
# sub open_next_file {                  #
#   my $self=shift;                     #
#   my $name=$self->next_file_name(@_); #
#   open my $fh, ">>", $name;           #
#   $fh;                                #
# }                                     #
#########################################

sub html_root {
  my $self=shift;
  $self->[html_root_];
}

sub current_set {
  my $self=shift;
  $self->[current_set_];
}

sub current_file {
  my $self=shift;
  $self->[current_file_];
}


sub set_prefix {
  my $self=shift;
  $self->[prefix_]=shift;
  $self->[current_set_]=undef;
}

sub flush {
  my $self=shift;
# remove all directories under the current prefix
  my $dir=$self->[html_root_]."/".$self->[prefix_];
  remove_tree $dir;

}
1;
