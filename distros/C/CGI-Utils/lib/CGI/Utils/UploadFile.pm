# -*-perl-*-
# Creation date: 2003-09-01 22:23:46
# Authors: Don
# Change log:
# $Id: UploadFile.pm,v 1.6 2004/10/24 10:33:08 don Exp $

use strict;

{   package CGI::Utils::UploadFile;

    use vars qw($VERSION);
    $VERSION = do { my @r=(q$Revision: 1.6 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };

    use vars qw($FH_COUNT $Have_File_Temp $Open_Flags);
    $FH_COUNT = 0;

    use Fcntl ();

    use overload '""' => '_asString', cmp => '_compareAsString', fallback => 1;

    BEGIN {
        local $SIG{__DIE__} = sub {};
        local $SIG{__WARN__} = sub {};
        $Have_File_Temp = eval 'require File::Temp; 1';
        $Open_Flags = Fcntl::O_RDWR()|Fcntl::O_CREAT();
        # Fcntl::O_EXCL(); - leave this out for now cuz it breaks File::Temp usage

        # idea taken from File::Temp
        unless ($^O eq 'MacOS') {
            my $bit = 0;
            $Open_Flags |= $bit if eval '$bit = Fcntl::O_TEMPORARY()';
        }
    }
    
    sub new {
        my ($proto, $name) = @_;
        no strict 'refs';
        (my $safe_name = $name) =~ s/([^a-zA-Z0-9_])/sprintf("%%%02x", ord($1))/eg;
        $FH_COUNT++;
        my $sub_name = "fh" . $FH_COUNT . "_" . $safe_name;
        my $ref = \*{"CGI::Utils::UploadFile::$sub_name"};
        my $self = bless $ref, $proto;
        return wantarray ? ($self, $sub_name) : $self;
    }

    sub new_from_handle {
        my ($proto, $file_name, $old_fh) = @_;
        my ($fh, $name_space) = $proto->new($file_name);

        # dup the old file handle
        open($fh, ">&", $old_fh);
        return $fh;
    }

    sub new_tmpfile {
        my ($proto, $file_name) = @_;

        my ($fh, $name_space) = $proto->new($file_name);

        my $tmp_file = '';

        if ($Have_File_Temp) {
            my $tmp_fh = File::Temp->new(UNLINK => 0);
            $tmp_file = $tmp_fh->filename;
        } else {
            my $tmp_dir = "/tmp";
            $tmp_file = $tmp_dir .
                "/_cgi_utils_" . sprintf("%x%x%x", 10000 + int rand(10000), time(), $$);
            for my $i (1 .. 20) {
                last unless -e $tmp_file;
                $tmp_file = $tmp_dir .
                    "/_cgi_utils_" . sprintf("%x%x%x", 10000 + int rand(10000), time(), $$);
            }
        }

        sysopen($fh, $tmp_file, $Open_Flags, 0600)
              or return undef;

        unlink $tmp_file;
        delete $CGI::Utils::UploadFile::{$name_space};

        return $fh;
    }

    sub filename {
        return shift()->_asString;
    }
    
    sub _asString {
        my ($self) = @_;

        (my $safe_name = $$self) =~ s/^.+::fh\d+_([^:]+)$/$1/;
        $safe_name =~ s/%([a-f0-9]{2})/chr(hex($1))/eg;
        return $safe_name;
    }

    sub _compareAsString {
        my ($self, $val) = @_;
        return "$self" cmp $val;
    }

    sub DESTROY {
        my ($self) = @_;
        close $self;
    }

}

1;

__END__

=pod

=head1 NAME

 CGI::Utils::UploadFile - 

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 METHODS


=head1 EXAMPLES


=head1 BUGS


=head1 AUTHOR


=head1 VERSION

$Id: UploadFile.pm,v 1.6 2004/10/24 10:33:08 don Exp $

=cut
