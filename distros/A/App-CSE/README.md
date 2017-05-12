# NAME

App::CSE - Code search engine. Implements the 'cse' program

# INSTALLATION

Using system wide cpan:

    sudo cpan -i App::CSE

Using cpanm:

    cpanm App::CSE

# SYNOPSIS

    cse

See [App::CSE::Command::Help](http://search.cpan.org/perldoc?App::CSE::Command::Help) For a description the available commands.

# PROGRAMMATIC USAGE

In addition of using this via the command line program 'cse', you can use this app
in an object oriented way.

For instance:

    my $app = App::CSE->new( { command\_name => 'index',
                               options => { 'idx' => '/path/to/the/index' ,
                                             'dir' => '/code/directory/to/index'
                                          });

    if( $app->execute() ){
        .. and error occured ..
    }else{
        .. It is a success ..
    }

Retrieving search hits after a search:

     my $app = App::CSE->new( { command\_name => 'search',
                                args => [ 'search\_query' ],
                                options => { 'idx' => '/path/to/the/index' ,
                                              'dir' => '/code/directory/to/index'
                                           });
    my $hits = $app->command()->hits();
    # This is a L<Lucy::Search::Hits>

See [App::CSE::Command::Help](http://search.cpan.org/perldoc?App::CSE::Command::Help) for a list of available commands and options.

# LOGGING

App::CSE uses [Log::Log4perl](http://search.cpan.org/perldoc?Log::Log4perl)

# BUILD STATUS

<a href="https://travis-ci.org/jeteve/App-CSE"><img src="https://travis-ci.org/jeteve/App-CSE.svg?branch=master"></a>

# COPYRIGHT

See [App::CSE::Command::Help](http://search.cpan.org/perldoc?App::CSE::Command::Help)