package CGI::FileUpload;

use warnings;
use strict;

=head1 NAME

CGI::FileUpload - A module to upload file through CGI asynchrnously, know where the upload status and get back the file from a third parties on the server

=head1 VERSION

=cut

our $VERSION = '0.03';

=head1 DESCRIPTION

An uploaded file is associated with a key (corresponding to a file in a server temp directory)

When uploading is started the key is returned before the uploading completed, allowing further queries such as knowing is the upload is completed, uploaded file size etc...

=head1 SYNOPSIS

    use CGI::FileUpload;

    my $fupload = CGI::FileUpload->new();
    ...

=head1 EXPORT


=head1 FUNCTIONS

=head3 uploadDirectory()

Returns the session upload directory (by default is $CGI_FILEUPLOAD_DIR or /defaulttempdir/CGI-FileUpload)

=head3 formString([parameter=>val]);

Returns a html <FORM> string such as
  <form name='cgi_fileupload' method='post' enctype='multipart/form-data'>
      <input type='file' name='uploadfile'/>
      <input type='hidden' name='action' value='upload'/>
      <input type='hidden' name='return_format' value='text'/>
      <input type='submit' value='upload'>
  </form>

Parameters can be of

=over 4

=item submit_value=>string: the value displayed on the "submit button"

=item return_format=>(keyonly|text|json): the type of output at submission time (default is keyonly, but a text key=value perl line, but json should also be possible)

=item form_name=>string the form name (default is 'cgi_fileupload'

=back

=head3 idcookie(query=>$cgi_query)

Either retrieves the id cookie or build one based one random number + ip

=head1 METHODS

=head2 Constructors

=head3 my $fupload=new CGI::FileUpload();

Creates a new instance in the temp directory

=head3 my $fupload=new CGI::FileUpload(suffix=>string);

Creates a file (thus returns a key)ending with .string

=head3 my $fupload=new CGI::FileUpload(key=>string);

Read info for an existing file being (or having been) uploaded.

=head2 Getting(/setting mor internal) info

=head3 $fupload->key()

returns the reference key

=head3 $fupload->from_ipaddr()

Returns the originated IP address

=head3 $fupload->from_id()

Returns some user id (hidden in a randomized cookie)

=head3 $fupload->upload_status()

Returns a string '(uploading|completed|killed)'

=head3 $fupload->properties

Returns a Util::Properties object associated (containing status and whatever info

=head3 $fupload->file()

Returns the local file associated with the uploaded file

=head2 Actions


=head3 $fupload->upload() (query=>$cgi_query [,opts])

Start the upload. A CGI::query must be passed. Other optional arguments can be of

=over 4 

=item asynchronous=>(1|0) to see if the transfer must be completed before returning (0 value). default is 1;

=back

=head3 $fupload->remove()

Removes the file upload structure from the temp directory

=head3 $fupload->kill([signal=>value])

Kill the uploading process (default signal is 'INT')

=head1 AUTHOR

Alexandre Masselot, C<< <alexandre.masselot at genebio.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cgi-fileupload at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-FileUpload>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::FileUpload


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-FileUpload>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-FileUpload>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-FileUpload>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-FileUpload>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2007 Alexandre Masselot, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
use File::Temp qw(tempfile);
use File::Spec;
use Util::Properties;
use File::Basename;
use File::Glob qw(:glob);

use Object::InsideOut 'Exporter';
BEGIN{
  our @EXPORT = qw(&uploadDirectory &idcookie);
  our @EXPORT_OK = ();
}

my @key: Field(Accessor => 'key', Permission => 'public');
my @props: Field(Accessor => '_props', Permission => 'private', Type=>'Util::Properties');

my %init_args :InitArgs = (
			   KEY=>qr/^key$/i,
			   SUFFIX=>qr/^suffix$/i,
			  );
sub _init :Init{
  my ($self, $h) = @_;

  if ($h->{KEY}){    #just a set of properties
    $self->key($h->{KEY});

    unless (-f $self->file(".properties")){
      open (FD, ">".$self->file(".properties")) or die "cannot create prop file [".$self->file(".properties")."]:$!";
      close FD;
    }
    $self->_props(Util::Properties->new(file=>$self->file(".properties")));
  }else{
    my ($fh, $file);
    if($h->{SUFFIX}){
      ($fh, $file)=tempfile(DIR=>uploadDirectory(), SUFFIX=>".$h->{SUFFIX}", UNLINK=>0);
    }else{
      ($fh, $file)=tempfile(DIR=>uploadDirectory(), UNLINK=>0);
    }
    my $key=basename($file);
    $self->key($key);
    my $fprop=$self->file(".properties");
    open(FD,  ">$fprop") or die "cannot open [$fprop]: $!";
    close FD;
    close $fh;

    my $prop=Util::Properties->new();
    $prop->file_isghost(1);
    $prop->file_name($self->file().".properties");
    $prop->prop_set('key', $key);
    $self->_props($prop);
  }
};

sub _automethod :Automethod{
  my ($self, $val) = @_;
  my $set=exists $_[1];
  my $subname=$_;

  if($subname=~/^(upload_status|pid|file_orig|size|from_ipaddr|from_id)$/){
    if($set){
      return sub{
	Carp::confess unless $self->_props;
	$self->_props->prop_set($subname, $val);
      }
    }else{
      return sub{
	return $self->_props->prop_get($subname);
      }
    }
  }
}

sub formString{
  my $self=shift;
  my %params=@_;
  $params{submit_value}||='upload';
  $params{return_format}||='keyonly';
  $params{form_name}||='cgi_fileupload';

  # TODO add support for oncompletion callback
  return <<EOT;
  <script language='javascript'>
    function activateKeySuff(me, other){
      other.disabled=(me.value != '');
    }
  </script>
  <form name='$params{form_name}' method='post' enctype='multipart/form-data'>
    <table border='0'>
      <tr>
        <td>
          <input type='file' name='uploadfile'/>
        </td>
      </tr>
      <tr>
        <td>
          suffix=<input type='text' name='suffix' size='5' onchange='activateKeySuff(this, this.form.key)'/> or key=<input type='text' name='key' ' onchange='activateKeySuff(this, this.form.suffix)'/>
        </td>
      </tr>
      <tr>
        <td>
          <input type='submit' value='$params{submit_value}'>
        </td>
      </tr>
      <input type='hidden' name='return_format' value='$params{return_format}'/>
      <input type='hidden' name='action' value='upload'/>
    </table>
  </form>
EOT
}

sub upload{
  my $self=shift;
  my %params=@_;
  my $query=$params{query} or Carp::confess("no query was passed");
  my $asynchronous=(exists $params{asynchronous})?$params{asynchronous}:1;

  my $filename=$query->param('uploadfile');

  $self->file_orig($filename);
  $self->pid($$);
  $self->from_ipaddr($ENV{REMOTE_ADDR});


  #upload
  my $localfile=$self->file();
  open (FHOUT, ">$localfile.part") or die "cannot open for writing [$$localfile.part]: $!";

  my $ret;
  my $retformat=$query->param('return_format') || 'keyonly';
  if($retformat eq 'keyonly'){
    $ret=$self->key();
  }elsif($retformat eq 'text'){
    $ret="key=".$self->key()."\n";
  }elsif($retformat eq 'json'){
    $ret='not yet...';
  }else{
    $query->header(-type=>'text/plain');
    die "unknown return_format [$retformat]";
  }

  my $id=idcookie(query=>$query);
  my $cookie=CGI::cookie(-name=>'cgi-fileupload-id',
			 -value=>$id,
			 -expires=>'+100d'
			);
  $self->from_id($id->{id});


  print $query->header(-type=>'text/plain',
		 -cookie=>$cookie,
		 -length=>(length($ret))+ $asynchronous?0:1,
		);
  print $ret;

  $self->upload_status('loading');
  my $fhin=CGI::upload('uploadfile')||CORE::die "cannot convert [$filename] into filehandle: $!";
  my $l=0;
  while(<$fhin>){
    $l+=length($_);
    print FHOUT $_;
  }
  close FHOUT;
  rename("$localfile.part", "$localfile") or die "cannot rename ($localfile.part, $localfile); $!";

  $self->size(-s $localfile);
  $self->upload_status('completed');
  $self->pid("");
}

sub file{
  my $self=shift;
  my $suffix=shift;
  my $ret=uploadDirectory()."/".$self->key();
  $ret.="$suffix" if defined $suffix;
  return $ret;
}

sub remove{
  my $self=shift;
  my %params=@_;
  $self->kill;
  foreach (glob $self->file('.*')){
    unlink $_ or die "cannot remove [$_]: $!";
  }
}

sub idcookie{
  my %params=@_;
  my $query=$params{query} or Carp::confess("no query was passed");
  my %idcookie=$query->cookie('cgi-fileupload-id');
  unless ($idcookie{id}){
    #build a random id key
    $idcookie{id}=$ENV{REMOTE_ADDR}."-".(int(rand()*10**15));
  }
  return \%idcookie;
}

sub kill{
  my $self=shift;
  my %params=@_;
  my $signal=$params{signal}||'INT';
  if(my $pid=$self->pid){
    kill $signal,$pid;
  }
}

sub uploadDirectory{
  my $dir=$ENV{CGI_FILEUPLOAD_DIR} || File::Spec->tmpdir()."/CGI-FileUpload";
  unless (-d $dir){
    mkdir $dir or die "cannot mkdir $dir:$!";
  }
  return $dir;
}


1; # End of CGI::FileUpload
