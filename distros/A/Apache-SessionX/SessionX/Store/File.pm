package Apache::SessionX::Store::File;

use strict;
use Symbol;
use vars qw($VERSION @ISA);

$VERSION = '2.00b5';

@ISA = ('Apache::Session::Store::File') ;

use Apache::Session::Store::File;

sub count_sessions 
    {
    my $self = shift;
    my $session = shift;
    
    my $directory = $session->{args}->{Directory} || die 'Directory param missing!';

    opendir(DIR,$directory);
    my $count = grep { /^[0-9a-fA-F]+$/ } readdir(DIR);
    closedir(DIR);
    
    return $count;
    # print STDERR "Apache::SessionX::Store::File ($tmp)--- we are here\n";
    }

sub first_session_id 
    { 
    my $self = shift;
    my $session = shift;
    my $file;
    
    my $directory = $session->{args}->{Directory} || die 'Directory param missing!';
    $self->{dir} = Symbol::gensym();
    opendir $self->{dir}, $directory;
    
    $file = readdir $self->{dir};
    while ($file && ($file !~ /^[0-9a-fA-F]+$/)) 
        {
	#print STDERR "\tfile: $file\n";
	$file = readdir $self->{dir};
	#print STDERR "\tfile/first: $file\n";
        }
    return $file;
    }   

sub next_session_id 
    { 
    my $self = shift;
    my $session = shift;
    my $file;
    
    return $self -> first_session_id ($session) if (!$self->{dir}) ;
    
    $file = readdir $self->{dir};
    while ($file && ($file !~ /^[0-9a-fA-F]+$/)) 
        {
	#print STDERR "\tfile: $file\n";
	$file = readdir $self->{dir};
	#print STDERR "\tfile/next: $file\n";
        }
    closedir $self->{dir} if (!$file) ;

    return $file;
    }   

1;

