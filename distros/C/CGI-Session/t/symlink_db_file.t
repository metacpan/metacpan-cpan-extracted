#/usr/bin/perl -T
# $Id: $

use strict;
use Carp;

use Test::More;
use CGI::Session;
use File::Spec;
{
    no strict 'refs';
    no warnings 'redefine';
    *CGI::Session::ErrorHandler::set_error = sub {
        my $class = shift;
        my $error = shift;
        croak $error if $error;
    };

}

eval 'require DB_File';    
plan skip_all => "DB_File not available" if $@;

if (! eval { symlink("",""); 1 }) {
    plan skip_all => "Your OS doesn't support symlinks";
}

plan tests => 11;

my ($path,$new_path) = ('t/cgisess_symlink.db','t/cgisess_symlink_link.db');
unlink($path,$new_path);
ok(my $s = CGI::Session->new('driver:db_file;id:static','symlink_session',{Directory=>'t',FileName=>'cgisess_symlink.db'}),'Create new session named symlink');
ok($s->id, 'We have an id');
$s->param('passthru',1);
$s->flush();

# test retrieve
ok(symlink($path,$new_path), 'Created symlink');
ok(-l $new_path, 'Check to make certain symlink was created');
ok(my $ns = CGI::Session->new('driver:db_file;id:static','symlink_session',{Directory=>'t',FileName=>'cgisess_symlink_link.db'}), 'Get our symlinked session');
ok(! -e $new_path || ! -l $new_path,'we should have wiped out the symlink');
isnt($ns->param('passthru'),1,'this session should be unique');

unlink($new_path);

# swap the symlink and session
ok(rename($path,$new_path),'moving session file');
ok(symlink($new_path,$path),'creating symlink');
$s->param('change',1);
ok($s->flush(),'flush should wipe out the symlink');
ok(! -l $path,'original session file has been restored');

# tidy it up
undef($_) for $s,$ns;
unlink($path,$new_path,map "$_.lck",$path,$new_path);
