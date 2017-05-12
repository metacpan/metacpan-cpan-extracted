package CGI::Ex::Recipes::Install;
use utf8;
use warnings;
use strict;
use Carp qw(croak);
use Data::Dumper;
use CGI();
use File::Find;
use File::Copy;
use File::Path;
use Cwd qw(realpath);
use File::Spec::Functions qw(rel2abs);
use IO::File;
use Config;
our $VERSION = '0.2';
our ($src,$dest);

#starts the install procedure
sub new {
    my $class = shift || croak "Usage: ".__PACKAGE__."->new";
    my $self  = ref($_[0]) ? shift() : (@_ % 2) ? {} : {@_};
    bless $self, $class;
    $self->_init;
    return $self;
}

#???
sub _init {
    my $self = shift;
    $self->{q} = CGI->new();
    if(!$self->{q}->param()){croak "Usage: ".usage()}
    #1. Guess the mode - offline is default
    
    #2. Collect info about the environment and exit gracefully if 
    #permissions or anything needed is missing
    return $self;
}

#install the application
sub run {
    my $self = shift;
    
    $self->{q}->print( Dumper( \%{$self->{q}->Vars()} ) );
    $self->install;
}

sub install {
        my $self = shift;
    #Yeah, there is File::Copy::Recursive but I needed a little fun.
    
    print '*' x 40, $/;
    print
        "CGI::Ex::Recipes - Example application using$/"
        ."CGI::Ex::App - Anti-framework application framework.$/";
    print '*' x 40, $/;
    
    print "Using $Config{perlpath} " . $Config{version} . ' on ' . $Config{'osname'} . $/;
    print 'Using UTF8LOCALE - GOOOD!' . $/ if ${^UTF8LOCALE};
    $src  = realpath( rel2abs $self->{q}->param('src') ) || croak('Please provide source directory.'.$/.usage() );
    $dest = realpath( rel2abs $self->{q}->param('dest') )|| croak('Please provide destination directory.'.$/.usage());

    
    #check if $src and $dest are the same.
    if ( $src eq $dest ) {
        print
            "Source path:'$src'$/should not be the same as $/"
            . "destination path: '$dest'$/... exiting."
            . $/;
        exit;
    }
    
    #check if $dest is under $src

=pod
    
    if ( $dest =~ /$src/ ) {
        print
            "Destination path: '$dest'$/ can not be under$/"
            . "source path: '$src'$/... exiting.$/";
        exit;
    }
    
=cut

    #check if $src and $dest exist
    if(!-e $src || !-d $src){
        print "Source path: '$src'$/does not exists or is not a directory$/"
            ."... exiting.$/";
        exit;
    }
    if(!-e $dest){
        eval { mkpath($dest) };
        if ($@) {
            print "Couldn't create $dest:$/$@$/" . "... exiting.$/";
            exit;
        }
    }elsif(!-d $dest) {
        print "Destination path: $/'$dest'$/exists but is not a directory$/"
            ."... exiting.$/";
        exit;
    }
    ##############################
    #blah ... we can start work...
    ##############################
    $self->_install($src,$dest);
}# end sub install

sub _install {
    my $self = shift;
    print "Installing $src/* to $dest/*...$/";
    #sleep 1;
    finddepth(
        {   wanted => sub {
                
                my $file = $File::Find::name;
                if (-l $file){
                    warn "$/Found link '$file'... skipping $/";
                    return;
                }
                if ( $file !~ /\.svn/ )
                {
                    #wow
                    my $file_dest = $file;
                    $file_dest =~s/^$src/$dest/;
                    my $dest_dir = $File::Find::dir;
                    $dest_dir =~s/^$src/$dest/;
                    print "Copying $file $/"
                         ."to:     $file_dest" . $/;
                    if ( !-e $dest_dir ){ mkpath($dest_dir)  }
                    if (  -d $file     ){ mkpath($file_dest) }
                    if ( !-d $file     ){
                        copy( $file, $file_dest) or die "Copy failed: $!";
                        
                        if($file_dest =~/\.(pl|cgi)$/) {
                            chmod 0755,$file_dest and change_shebang_sitepackage_and_siteroot($file_dest);
                        }elsif($file_dest =~/(httpd\.conf)$/){
                            my $fh = IO::File->new("< $file_dest");
                            my @lines;
                            ( $fh->binmode and @lines =  $fh->getlines and $fh->close ) || die $!;
                            foreach ( 0 .. @lines-1 ) {
                               $lines[$_] =~ s|#Include (.*?)|#Include $dest|;
                                $lines[$_] =~ s|Directory "(.*?)"|Directory "$dest"| ;
                                $lines[$_] =~ s|PerlRequire\s+(.*?)/perl/bin/startup.pl|PerlRequire $dest/perl/bin/startup.pl|;

                            }
                            $fh = IO::File->new("> $file_dest");     
                            $fh->binmode and $fh->print(@lines) and $fh->close;
                        }
                        
                    }
                        #make (tmp|conf|logs|data|files) and below world writable so the server can write there
                        #TODO:think about a safer/smarter way
                        chmod 0777,$file_dest
                            if($file_dest =~/(tmp|conf|logs|data|files)/);
                        #TODO:REMEMBER to write a script which will change permissions as needed
                    #sleep 1;

                }
    
            },
            no_chdir => 1,
        },
        $src
    );


}#end sub _install

sub usage {
    'Usage:'.$/.$0 .' src=/from/path dest=/to/path'.$/;
}
sub change_shebang_sitepackage_and_siteroot {
    my ( $file ) = @_;
    my $fh = IO::File->new("< $file");
    my @lines;
    ( $fh->binmode and @lines =  $fh->getlines and $fh->close ) || die $!;
    my $new_shebang = "$Config{perlpath}".$Config{_exe};
    $new_shebang && $lines[0]=~ s/^#!\s*\S+/#!$new_shebang/s ;
    my $new_package = $dest; 
    $new_package =~ s|/|_|g;
    foreach ( 0 .. @lines-1 ) {
        $lines[$_]=~ s/package\s+ourobscurepackage/package $new_package/ ;
        $lines[$_]=~ s/\$ENV\{SITE_ROOT\}\s*?=.+/\$ENV\{SITE_ROOT\} = '$dest';/;
    }
    $fh = IO::File->new("> $file");     
    ( $fh->binmode and $fh->print(@lines) and $fh->close ) || die $!;
}


1;
