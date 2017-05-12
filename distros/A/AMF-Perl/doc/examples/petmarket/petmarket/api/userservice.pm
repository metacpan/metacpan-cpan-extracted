package petmarket::api::userservice;

# Copyright (c) 2003 by Vsevolod (Simon) Ilyushchenko. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

#This is server side for the Macromedia's Petmarket example.
#See http://www.simonf.com/amfperl for more information.

use warnings;
use strict;

use petmarket::api::dbConn;
use vars qw/@ISA/;
@ISA=("petmarket::api::dbConn");

use AMF::Perl::Util::Object;

sub methodTable
{
    return {
        "addUser" => {
            "description" => "Add a user with the given credentials",
            "access" => "remote", 
        },
        "getUser" => {
            "description" => "Add a user with the given credentials",
            "access" => "remote", 
        },
        "updateUser" => {
            "description" => "Add a user with the given credentials",
            "access" => "remote", 
        },
    };
    
}

my @userFields = ("firstname", "lastname", "homestreet1", "homestreet2", "homecity", "homestate", "homecountry", "homezip", "homephone", "creditcardnumber", "creditcardtype", "creditcardexpiry");

my @shippingFields = ("shippingstreet1", "shippingstreet2", "shippingcity", "shippingcountry", "shippingzip", "shippingphone"); 

my @fields = ("email", "password", @userFields, @shippingFields);

sub authenticate
{
    my ($self, $email, $password) = @_;
    my $ary_ref = $self->dbh->selectall_arrayref("SELECT count(*) FROM user_details where email='$email' AND password='$password'");

    return $ary_ref->[0]->[0] > 0;
}

sub addUser
{
    my ($self, $email, $password) = @_;
	
    $self->dbh->do("INSERT INTO user_details set email='$email', password='$password'");

    my $result = new AMF::Perl::Util::Object;
    $result->{"useroid"} = $email;
    $result->{"email"} = $email;
    $result->{"password"} = $password;

    return $result;
}


sub getUser
{
  my ($self, $email, $password) = @_;

    return 0 unless $self->authenticate($email, $password);

    my $result = new AMF::Perl::Util::Object;

    my $hash_ref = $self->dbh->selectall_hashref("SELECT * FROM user_details WHERE email='$email'", "email");

    my $rowRef = $hash_ref->{$email};

    foreach my $field (@fields)
    {
        $result->{$field} = $rowRef->{$field};
    }
    $result->{useroid} = $email;
    return $result;
}

sub updateUser
{
    my ($self, $userObject) = @_;

    return 0 unless $self->authenticate($userObject->{"email"}, $userObject->{"password"});

    my $setString = "";

    my @setStringArray = map {"$_='".$userObject->{$_}."'"} @userFields;
    $setString = join ",", @setStringArray;

    $self->dbh->do("UPDATE user_details SET $setString");

    return $userObject;
}

1;
