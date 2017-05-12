#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

our $ONLINE;


BEGIN {
    $ONLINE = $ENV{host} && $ENV{user} && $ENV{password};
}
use Test::More tests => $ONLINE ? 10 : 2;

my $test_host     = $ENV{host};
my $test_user     = $ENV{user};
my $test_password = $ENV{password};

ok(1, 'Test OK');
use_ok('API::ISPManager');

no warnings 'once';

$API::ISPManager::DEBUG = 0;

### ONLINE TESTS
exit if !$ONLINE;

my %connection_params = (
    username => $test_user,
    password => $test_password,
    host     => $test_host,
    path     => 'manager',
);

# Получение списка файлов
my $file_list_answer = API::ISPManager::file::list( { %connection_params } );
ok($file_list_answer, 'file list');
my @original_file_list = get_file_list('', '');

# Создание файла
my $now = time;
my $file_create = API::ISPManager::file::create( {
    %connection_params,
    filetype => 0,
    name => "$now.test",  
    plid => '',  
} );

my @expected_file_list = @original_file_list;
push @expected_file_list, "$now.test";
my @real_file_list = get_file_list('', '');
ok(!union_equal(\@original_file_list, \@real_file_list), 'file creation - check difference exists');
ok(union_equal(\@expected_file_list, \@real_file_list), 'file creation - check created file name');

# Удаление файла
my $file_delete = API::ISPManager::file::delete( {
    %connection_params,
    elid => "$now.test",  
    plid => '',    
} );
@real_file_list = get_file_list('', '');
ok(union_equal(\@original_file_list, \@real_file_list), 'file delete');

# Копирование файла
$now = time;
API::ISPManager::file::create( {
    %connection_params,
    filetype => 0,
    name => "$now.test",  
    plid => '',  
} );

API::ISPManager::file::create( {
    %connection_params,
    filetype => 1,
    name => "$now",  
    plid => '',  
} );

my $file_copy = API::ISPManager::file::copy( {
    %connection_params,
    elid => "$now.test",  
    plid => "$now",
} );

@expected_file_list = ("$now.test");
@real_file_list = get_file_list('', $now);
ok(union_equal(\@expected_file_list, \@real_file_list), 'file copy');

API::ISPManager::file::delete( {
    %connection_params,
    elid => "$now.test",  
    plid => '',    
} );

API::ISPManager::file::delete( {
    %connection_params,
    elid => "$now",  
    plid => '',    
} );

# Перемещение файла
$now = time;
API::ISPManager::file::create( {
    %connection_params,
    filetype => 0,
    name => "$now.test",  
    plid => '',  
} );

API::ISPManager::file::create( {
    %connection_params,
    filetype => 1,
    name => "$now",  
    plid => '',  
} );

my $file_move = API::ISPManager::file::move( {
    %connection_params,
    elid => "$now.test",  
    plid => "$now",
} );

@expected_file_list = ("$now.test");
@real_file_list = get_file_list('', $now);
ok(union_equal(\@expected_file_list, \@real_file_list), 'file move');

API::ISPManager::file::delete( {
    %connection_params,
    elid => "$now",  
    plid => '',    
} );

# Загрузка файла
$now = time;
open my $fh, '>', $now or die "Can't open $now for writing: $!";
print {$fh} 'hello world';
close $fh;

my $upload_result = API::ISPManager::file::upload( {
    %connection_params,
    plid => '',
    file => $now,
} );

@expected_file_list = @original_file_list;
push @expected_file_list, $now;
@real_file_list = get_file_list('', '');
ok(union_equal(\@expected_file_list, \@real_file_list), 'file upload');

API::ISPManager::file::delete( {
    %connection_params,
    elid => "$now",  
    plid => '',    
} );

# Распаковка архива
`tar -czf $now.tar.gz $now`;
API::ISPManager::file::upload( {
    %connection_params,
    plid => '',
    file => "$now.tar.gz",
} );

my $extract_result = API::ISPManager::file::extract( {
    %connection_params,
    plid => '',
    elid => "$now.tar.gz",
} );

@expected_file_list = @original_file_list;
push @expected_file_list, $now;
push @expected_file_list, "$now.tar.gz";
@real_file_list = get_file_list('', '');
ok(union_equal(\@expected_file_list, \@real_file_list), 'file extract');

API::ISPManager::file::delete( {
    %connection_params,
    elid => "$now",  
    plid => '',    
} );

API::ISPManager::file::delete( {
    %connection_params,
    elid => "$now.tar.gz",  
    plid => '',    
} );

unlink $now;
unlink "$now.tar.gz";

# Получение списка файлов в виде массива
sub get_file_list {
    my ($plid, $elid) = @_;
    my $answer = API::ISPManager::file::list( { 
        %connection_params, 
        plid => $plid, 
        elid => $elid,
    } );
    my @result;
    if (ref($answer->{elem}) eq 'ARRAY') {
        foreach my $elem (@{$answer->{elem}}) {
            push @result, $elem->{name}->{content};
        }
    }
    else {
        push @result, $answer->{elem}->{name}->{content};
    }
    return @result;
}

# Сравнение двух массивов как множеств - т.е. без учета порядка числа
# элементов и числа их повторений
sub union_equal {
    my ($a, $b) = @_;
    return union_part_of($a, $b) && union_part_of($b, $a);
}

sub union_part_of {
    my ($a, $b) = @_;
    my $result = 1;
    for (my $i = 0; $i < scalar @{$a} && $result; $i++) {
        my $sub_result = 0;
        for (my $j = 0; $j < scalar @{$b} && !$sub_result; $j++) {
            $sub_result = $sub_result || ${$b}[$j] eq ${$a}[$i];
        }
        $result = $result && $sub_result;
    }
    
    return $result;
}
