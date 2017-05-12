#TODO Header documentation
#TODO Make some methods




package Comskil::JServer;

=head1 NAME

Comskil::JWand - The great new Comskil::JWand!

=head1 VERSION

Version 0.1

=cut

use strict;
use warnings;

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Comskil::JWand;

    my $foo = Comskil::JWand->new();
    ...
=cut

BEGIN {
    use Exporter;
	
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
 
    $VERSION = '0.10';
    @ISA = qw( Exporter );
    @EXPORT	= qw( );
    @EXPORT_OK = qw( );
    %EXPORT_TAGS = ( ALL => [ qw(  ) ] );
}

END { }

=head1 EXPORT
A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=over 8

=item sub new()

=item sub getJProject()

=item sub getJIssue()

=item sub getJIssueFromKey()

=item findJIssueFromJQL()

=item getAttachmentList()

=back

=head1 SUBROUTINES/METHODS

=cut




sub new {
	my ($class,@args) = @_;
	my $self = ( );
	bless($self,$class);
	
	return($self);
}

sub getJProject {
	my ($self,@args) = @_;
	return($self);
}

sub getJIssue {
	my ($self,@args) = @_;
	return($self);
}

sub getJIssueFromKey {
	my ($self,@args) = @_;
	return($self);
}
	
sub findJIssueFromJQL {
	my ($self,@args) = @_;
	return($self);
}

sub getAttachmentList {
	my ($self,@args) = @_;
	return($self);
}

=head2 grabAttachmentFile()
=cut

sub grabAttachmentFile {
	my ($self,@args) = @_;
	return($self);
}

=head2 mirrorAttachmentFile()
=cut

sub mirrorAttachmentFile {
	my ($self,@args) = @_;
	return($self);
}

=head2 setField()
=cut 

sub setField {
	my ($self,@args) = @_;
	return($self);
}

=head2 setProject()
=cut

sub setProject {
	my ($self,@args) = @_;
	return($self);
}

=head2 addJQueue()
=cut

sub addJQueue {
	my ($self,@args) = @_;
	return($self);
}



BEGIN {
    use Exporter ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    $VERSION = '0.10';
    @ISA    = qw(Exporter);
    @EXPORT	= qw(
    	findJIssueFromJQL 
    	getJIssue 
    	getJIssueFromKey 
    	getJIssueAttachments 
    	setJIssueField
    	getJProject
    	setProject 
    	addJQueue
    	);
    %EXPORT_TAGS = ( );  ## e.g.  TAG => [ qw!name1 name2! ],
    @EXPORT_OK   = ( );  ## qw($Var1 %Hashit &func3);
}
 
our @EXPORT_OK;

END { }


1;
__END__
### EOF ###



=head3 code

my $js = Comskil::JServer->new();       # returns reference to JServer object

my $jp = $js->getJProject();            # returns reference to project structure

my $ji = $js->getJIsssue()              # returns reference to JIssue object
         $js->getJIssueFromKey($key)
         $js->getJIssueFromJQL($jql)
         
my $rc = $ji->setFields( $field => $value, ... )
         $ji->saveChanges()
         $ji->addComment()

my $ps = Comskil::PopServer->new();
         $ps->getMsgC