use strict;
use warnings;

use Test::More;
use File::Find qw(find);

plan skip_all => 'Needs Test::Pod' if not eval "use Pod::Simple::Checker; 1";

plan tests => 1;


my @errors;
find({wanted => \&check, no_chdir => 1}, '.');

#is($errors, '');
use Data::Dumper;
#diag Dumper \@errors;
is_deeply(\@errors, [], 'no errors');


sub check {
    return if $_ !~ /\.pm$/;
    my $p = Pod::Simple::Checker->new;
    my $errors;
    $p->output_string(\$errors);
    $p->parse_file($File::Find::name);
    #$p->parose_file('/home/gabor/work/szabgab/trunk/CGI-FileManager/t/lib/CGI/FileManager/Test.pm');
    push @errors, $errors if $errors;
    return;
}




