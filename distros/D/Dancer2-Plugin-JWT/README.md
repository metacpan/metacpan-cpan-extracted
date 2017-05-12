# NAME

Dancer2::Plugin::JWT - JSON Web Token made simple for Dancer2

# SYNOPSIS

     use Dancer2;
     use Dancer2::Plugin::JWT;

     post '/login' => sub {
         if (is_valid(param("username"), param("password"))) {
            jwt { username => param("username") };
            template 'index';
         }
         else {
             redirect '/';
         }
     };

     get '/private' => sub {
         my $data = jwt;
         redirect '/ unless exists $data->{username};

         ...
     };

# DESCRIPTION

Registers the `jwt` keyword that can be used to set or retrieve the payload
of a JSON Web Token.

To this to work it is required to have a secret defined in your config.yml file:

    plugins:
       JWT:
           secret: "my little secret"

# BUGS

I am sure a lot. Please use GitHub issue tracker 
[here](https://github.com/ambs/Dancer2-Plugin-JWT/).

# ACKNOWLEDGEMENTS

To Lee Johnson for his talk "JWT JWT JWT" in YAPC::EU::2015.

To Yuji Shimada for JSON::WebToken.

To Nuno Carvalho for brainstorming and help with testing.

# COPYRIGHT AND LICENSE

Copyright 2015 Alberto Simões, all rights reserved.

This module is free software and is published under the same terms as Perl itself.

# AUTHOR

Alberto Simões `<ambs@cpan.org>`
