# $Id: Text.pm,v 1.1.1.1 2004/06/28 19:24:28 veselosky Exp $
package CGI::Builder::Auth::UserAdmin::Text;
use CGI::Builder::Auth::UserAdmin ();
use Carp ();
use strict;
use vars qw(@ISA $DLM $VERSION);
@ISA = qw(CGI::Builder::Auth::UserAdmin::DBM CGI::Builder::Auth::UserAdmin);
$VERSION = (qw$Revision: 1.1.1.1 $)[1];
$DLM = ":";

my %Default = (PATH => ".", 
	       DB => ".htpasswd", 
	       FLAGS => "rwc",
	       );

sub new {
    my($class) = shift;
    my $self = bless { %Default, @_ }, $class;

    #load the DBM methods
    $self->load("CGI::Builder::Auth::UserAdmin::DBM");

    $self->db($self->{DB}); 
    return $self;
}

#do this so we can borrow from the DBM class

sub _tie {
    my($self) = @_;
    my($fh,$db) = ($self->gensym(), $self->{DB});
    printf STDERR "%s->_tie($db)\n", $self->class if $self->debug;

    $db =~ /^([^<>;|]+)$/ or Carp::croak("Bad file name '$db'"); $db = $1; #untaint
    open($fh, $db) or return;
    my($key,$val);
    
    while(<$fh>) { #slurp! need a better method here.
	($key,$val) = $self->_parseline($fh, $_);
	$self->{'_HASH'}{$key} = $val; 
    }
    CORE::close $fh;
}

sub _untie {
    my($self) = @_;
    return unless exists $self->{'_HASH'};
    $self->commit;
    delete $self->{'_HASH'};
}

sub commit {
     my($self) = @_;
     return if $self->readonly;
     my($fh,$db) = ($self->gensym(), $self->{DB});
     my($key,$val);

     $db =~ /^([^<>;|]+)$/ or return (0, "Bad file name '$db'"); $db = $1; 
#untaint
     my $tmp_db = "$db.$$"; # Use temp file until write is complete.
     open($fh, ">$tmp_db") or return (0, "open: '$tmp_db' $!");

     while(($key,$val) = each %{$self->{'_HASH'}}) {
         print $fh $self->_formatline($key,$val)
            or return (0, "print: '$tmp_db' failed: $!");
     }
     CORE::close $fh
        or return (0, "close: '$tmp_db' failed: $!");
     my $mode = (stat $db)[2];
     chmod $mode, $tmp_db if $mode;
     rename( $tmp_db,$db )
        or return (0, "rename '$tmp_db' to '$db' failed: $!");
     1;
}

sub _parseline {
    my($self,$fh,$line) = @_;
    chomp $line;
    my($key, $val) = split($DLM, $line, 2);
    return ($key,$val);
}

sub _formatline {
    my($self,$key,$val) = @_;
    join($DLM, $key,$val) . "\n";
}

package CGI::Builder::Auth::UserAdmin::Text::_generic;
use vars qw(@ISA);
@ISA = qw(CGI::Builder::Auth::UserAdmin::Text
	  CGI::Builder::Auth::UserAdmin::DBM);

1;

__END__





