use strict ;
use warnings ;

{
commands =>
	{
        class => 'App::Plog::Commands',
        },

rcs =>
	{
        class => 'App::Plog::RCS::Git',
        entry_directory => 't/git_repository',
        },

renderer =>
        {
        class => 'App::Plog::Renderer::Extension',

        renderers =>
                {
                '.pod$' =>
                        {
                        class => 'App::Plog::Renderer::HTML::Pod',
                        css => 'sco.css'
                        },
                '.txt$' =>
                        {
                        class => 'App::Plog::Renderer::HTML::Asciidoc',
                        },
                '.' => # default to pod
                        {
                        class => 'App::Plog::Renderer::HTML::Pod',
                        css => 'sco.css'
                        },
                },
        },

aggregator =>
        {
        class => 'App::Plog::Aggregator::Template::Inline',

        # information passed to the Aggregator
        template => 'frame.html',
        feed_tag => 'FEED_TAG',
        entries_tag => 'ENTRIES_TAG',
	result_file => 'plog.html',
        },

feed =>
        {
        class => 'App::Plog::Feed::Atom',
	page => 'http://www.khemir.net/http_share/plog/plog.html', 
	} ,
	
destination_directory => '/home/nadim/Desktop/http_share/plog',
elements_directory => 'elements', #relative to blog root directory, can contain css, images, ...

update_script => 
        sub
		{
		my ($configuration, $blog_directory, $temporary_directory) = @_ ;
 
		use File::Copy::Recursive qw/dircopy fcopy/ ;
		$File::Copy::Recursive::KeepMode = 0 ;
		
		dircopy($temporary_directory, $configuration->{destination_directory}) or die $! ;
		},
}

