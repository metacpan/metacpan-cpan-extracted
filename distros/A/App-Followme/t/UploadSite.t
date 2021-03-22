#!/usr/bin/env perl
use strict;

use IO::File;
use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

use Test::More tests => 13;

#----------------------------------------------------------------------
# Load package

my @path = splitdir(rel2abs($0));
pop(@path);
pop(@path);

my $lib = catdir(@path, 'lib');
unshift(@INC, $lib);

eval "use App::Followme::FIO";
require App::Followme::UploadSite;

my $test_dir = catdir(@path, 'test');
my $local_dir = catdir(@path, 'test', 'local');
my $remote_dir = catdir(@path, 'test', 'remote');
my $state_dir = catdir(@path, 'test', 'local', '_state');

rmtree($test_dir);
mkdir $test_dir or die $!;
chmod 0755, $test_dir;
mkdir $local_dir or die $!;
chmod 0755, $local_dir;
mkdir $remote_dir or die $!;
chmod 0755, $remote_dir;
mkdir $state_dir or die $!;
chmod 0755, $state_dir;

chdir $local_dir or die $!;

my %configuration = (
                     top_directory => $local_dir,
                     remote_directory => $remote_dir,
                     remote_url => 'http://www.test.com',
                     upload_pkg => 'App::Followme::UploadLocal',
                    );

#----------------------------------------------------------------------
# Test read and write files

do {
    my $up = App::Followme::UploadSite->new(%configuration);

    my $user_ok = 'gandalf';
    my $password_ok = 'wizzard';

    my $cred_file = catfile(
                            $up->{top_directory},
                            $up->{state_directory},
                            $up->{credentials},
                           );

    $up->write_word($cred_file, $user_ok, $password_ok);

    my ($user, $pass) = $up->read_word($cred_file);
    is($user, $user_ok, 'Read user name'); # test 1
    is($pass, $password_ok, 'Read password'); # test 2

    my $hash_file = catfile($up->{top_directory},
                            $up->{state_directory},
                            $up->{hash_file});

    my $hash_ok = {'file1.html' => '014e32',
                   'file2.html' => 'a31571',
                   'sub' => 'dir',
                   'sub/file3.html' => '342611'
                  };

    $up->write_hash_file($hash_ok);

    my $hash = $up->read_hash_file($hash_file);
    is_deeply($hash, $hash_ok, 'read and write hash file'); # test 3

    my $local;
    my %local_ok = map {$_ => 1} keys(%$hash_ok);

    ($hash, $local) = $up->get_state();
    is_deeply($local, \%local_ok, 'compute local hash'); # test 4
    is_deeply($hash, $hash_ok, 'get hash'); # test 5

    unlink($hash_file);
};

#----------------------------------------------------------------------
# Test synchronization

do {

    my $page = <<'EOQ';
<html>
<head>
<meta name="robots" content="archive">
<!-- section meta -->
<base href="file:///test/" />
<title>Post %%</title>
<!-- endsection meta -->
</head>
<body>
<!-- section content -->
<h1>Post %%</h1>

<p>All about !!.</p>
<!-- endsection content -->
</body>
</html>
EOQ

    my $up = App::Followme::UploadSite->new(%configuration);

    my $local = {};
    my $hash_ok = {};
    foreach my $dir (('', 'sub')) {
        if ($dir) {
            my $directory = catdir($local_dir, $dir);
            mkdir $directory;
            chmod 0755, $directory;

            $local->{$dir} = 1;
            $hash_ok->{$dir} = 'dir';
        }

        foreach my $count (qw(one two three)) {
            my $output = $page;
            $output =~ s/!!/$dir/g;
            $output =~ s/%%/$count/g;

            my $file = $dir ? catfile($dir, "$count.html") : "$count.html";
            my $filename = catfile($local_dir, $file);
            fio_write_page($filename, $output);

            $local->{$file} = 1;
            $hash_ok->{$file} = ${$up->{data}->build('checksum', $filename)};

            my $new_page = $up->rewrite_base_tag($page);
            like($new_page, qr(<base href="$up->{remote_url}"),
                 "Rewrite base tag for $filename"); # test 6-11

        }
    }


    my $hash = {};
    my %saved_local = %$local;
    $up->update_folder($up->{top_directory}, $hash, $local);

    is_deeply($local, {}, 'Find local files'); # test 12
    is_deeply($hash, $hash_ok, 'Compute hash'); # test 13
};
