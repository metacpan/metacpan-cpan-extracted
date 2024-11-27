use strict;
use warnings;

use Test::More;
use App::PasswordManager;
use File::HomeDir;
use File::Spec;
use JSON;
use File::Temp qw/tempfile/;

subtest 'new' => sub {
    my ($fh, $tempfile) = tempfile();

    my $password_manager = App::PasswordManager->new(file => $tempfile);
    isa_ok($password_manager, 'App::PasswordManager');
    
    is_deeply($password_manager->{passwords}, {}, 'Password list should be empty');
};

subtest 'add_password' => sub {
    my ($fh, $tempfile) = tempfile();

    my $password_manager = App::PasswordManager->new(file => $tempfile);
    
    my $login = "user1";
    my $password = "password123";
    my $count = $password_manager->add_password($login, $password);
    
    is($count, 1, "Password count should be 1 after adding a password");

    my $passwords = $password_manager->{passwords};
    ok(exists $passwords->{$login}, "Password for login '$login' should exist");
    
    ok($passwords->{$login}{password} ne $password, "Password should be hashed");
};

subtest 'list_passwords' => sub {
    my ($fh, $tempfile) = tempfile();

    my $password_manager = App::PasswordManager->new(file => $tempfile);

    $password_manager->add_password("user1", "password123");
    $password_manager->add_password("user2", "password456");

    my $passwords = $password_manager->list_passwords();

    is_deeply([sort @$passwords], [sort qw(user1 user2)], 'Passwords should be listed regardless of order');
};

subtest 'remove_password' => sub {
    my ($fh, $tempfile) = tempfile();

    my $password_manager = App::PasswordManager->new(file => $tempfile);
    
    $password_manager->add_password("user1", "password123");

    my $result = $password_manager->remove_password("user1");
    is($result, 1, 'Password should be removed');

    my $passwords = $password_manager->{passwords};
    ok(!exists $passwords->{user1}, "Password for login 'user1' should be removed");
};

subtest 'edit_password' => sub {
    my ($fh, $tempfile) = tempfile();

    my $password_manager = App::PasswordManager->new(file => $tempfile);

    $password_manager->add_password("user1", "password123");

    my $new_password = "newpassword456";
    $password_manager->edit_password("user1", $new_password);

    my $passwords = $password_manager->{passwords};
    is($passwords->{user1}{password}, $password_manager->{pbkdf2}->generate($new_password, $password_manager->{salt}), 'Password should be updated');
};

subtest 'add_password_with_existing_login' => sub {
    my ($fh, $tempfile) = tempfile();

    my $password_manager = App::PasswordManager->new(file => $tempfile);

    $password_manager->add_password("user1", "password123");

    eval {
        $password_manager->add_password("user1", "newpassword456");
    };

    like($@, qr/Login 'user1' already exists/, "Adding password with existing login should throw an error");
};

subtest 'remove_password_not_found' => sub {
    my ($fh, $tempfile) = tempfile();

    my $password_manager = App::PasswordManager->new(file => $tempfile);

    eval {
        $password_manager->remove_password("nonexistent_user");
    };

    like($@, qr/Login 'nonexistent_user' not found/, "Removing password for a non-existent login should throw an error");
};

subtest 'edit_password_not_found' => sub {
    my ($fh, $tempfile) = tempfile();

    my $password_manager = App::PasswordManager->new(file => $tempfile);

    eval {
        $password_manager->edit_password("nonexistent_user", "newpassword456");
    };

    like($@, qr/Login 'nonexistent_user' not found/, "Editing password for a non-existent login should throw an error");
};

done_testing();
