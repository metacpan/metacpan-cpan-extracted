# NAME

Dancer2::Template::Haml - Text::Haml template engine wrapper for Dancer2

# SYNOPSIS

To use this engine, you may configure [Dancer2](https://metacpan.org/pod/Dancer2) via `config.yaml`:

    template: "haml"
    engines:
      template:
        haml: 
          cache: 1
          cache_dir: "./.text_haml_cache"

Or you may also change the rendering engine by setting it manually with `set` keyword:
 

    set template => 'haml';
    set engines => {
          template => {
            Haml => {
              cache => 1,
              cache_dir => './.text_haml_cache'
            },
          },
    };

Example:

`views/index.haml`:

    %h1= $foo

`views/layouts/main.haml`:

    !!! 5
    %html
      %head
        %meta(charset = $settings->{charset})
        %title= $settings->{appname}
      %body
        %div(style="color: green")= $content
        #footer
          Powered by
          %a(href="https://metacpan.org/release/Dancer2") Dancer #{$dancer_version}

A Dancer 2 application:

    use Dancer2;

    get '/' => sub {
      template 'index' => {foo => 'Bar!'};
    };

# DESCRIPTION
 

This is an interface between Dancer2's template engine abstraction layer and
the [Text::Haml](https://metacpan.org/pod/Text::Haml) module.
 

Based on the [Dancer2::Template::Xslate](https://metacpan.org/pod/Dancer2::Template::Xslate) and [Dancer::Template::Haml](https://metacpan.org/pod/Dancer::Template::Haml) modules.

You can use templates and layouts defined in \_\_DATA\_\_ section:

    use Dancer2;

    use Data::Section::Simple qw/get_data_section/;

    my $vpath = get_data_section;

    set layout => 'main';
    set appname => "Dancer2::With::Haml";
    set charset => "UTF-8";

    set template => 'haml';
    set engines => {
          template => {
            Haml => {
              cache => 1,
              cache_dir => './.text_haml_cache',
              path => $vpath,
            },
          },
    };

    get '/bazinga' => sub {
        template 'bazinga' => {
          text => 'Bazinga?',
          foo => 'Bar!',
        };
    };

    true;

    __DATA__
    @@ layouts/main.haml
    !!! 5
    %html
      %head
        %meta(charset = $settings->{charset})
        %title= $settings->{appname} 
      %body
        %div(style="color: green")= $content
        #footer
          Powered by
          %a(href="https://metacpan.org/release/Dancer2") Dancer #{$dancer_version}

    @@ bazinga.haml
    %strong= $text
    %p= $foo
    %em text 2 texts 3

# SEE ALSO

- [Dancer::Template::Haml](https://metacpan.org/pod/Dancer::Template::Haml)

    Haml rendering engine for Dancer 1.

- [Text::Haml](https://metacpan.org/pod/Text::Haml)

    Haml Perl implementation

# DEVELOPMENT

## Repository

    https://github.com/TheAthlete/Dancer2-Template-Haml

# AUTHOR

Viacheslav Koval, <athlete AT cpan DOT org>

# LICENSE

Copyright © 2013 by Viacheslav Koval.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
