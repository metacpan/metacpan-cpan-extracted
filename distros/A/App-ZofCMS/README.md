# NAME

App::ZofCMS - web framework and templating system for small-medium sites.

# SYNOPSIS

This module is just the main documentation for ZofCMS framework. See
["USING THE FRAMEWORK"](#using-the-framework) section below for explanation of how to use this
framework.

# WARNING

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-warning.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

I have no desire to continue development or maintenance of this framework.
As far as I know, I am the only developer. My only ties to this
framework is its use at $work and I am actively trying to switch
to [Mojolicious](https://metacpan.org/pod/Mojolicious). For that reason,
I strongly recommend you do NOT use this framework. Please see
[Mojolicious](https://metacpan.org/pod/Mojolicious), [Catalyst](https://metacpan.org/pod/Catalyst), [Dancer](https://metacpan.org/pod/Dancer), or [Dancer2](https://metacpan.org/pod/Dancer2) as alternatives.

<div>
    </div></div>
</div>

# DESCRIPTION

ZofCMS stands for "Zoffix's Content Management System", however I prefer
it to be just a name. It is a small web framework/templating system designed
to be easily installed and workable on limited severs, i.e. the ones that do
not allow you to install perl modules from CPAN, don't have ssh and
occasionally don't even offer any SQL databases. If you have more freedom
than that you may want to give [Catalyst](https://metacpan.org/pod/Catalyst) a try which, my opinion, is
a great framework, not just for web, and it offers far more functionality
than ZofCMS ever will.

ZofCMS is plugin based. If you create your own plugins, please upload them
to [App::ZofCMS::Plugin](https://metacpan.org/pod/App::ZofCMS::Plugin) namespace or email it to me (`zoffix@cpan.org`)
and I will package it, upload it, and give you corresponding credits.

ZofCMS currently uses [HTML::Template](https://metacpan.org/pod/HTML::Template) as a module to interpret HTML
templates. And so far, I have no plans to change this to anything alike
[Template::Toolkit](https://metacpan.org/pod/Template::Toolkit).

Despite the "core" of the framework along with all of its plugins being
on CPAN there is a helper script (`zofcms_helper`) which can produce
a ready-for-upload set of files which you can simply upload to your server
without having to install anything from CPAN on the server itself. See
`perldoc zofcms_helper`.

# HYSTORY

This section does not say anything useful, you can skip it if you are
not interested in what made me create ZofCMS.

For about two-three years name "ZofCMS" lived more as a joke. A lot of
people in IRC channels such as `#css` would ask me what web framework
I use (I didn't use any at the time) and I would gladly say "I use ZofCMS"
instead of the expected "Drupal" or "Wordpress".

After coding a templating system from scratch for
one of the sites, which runs on the server without any SQL, ssh
or ability to install any perl modules directly from CPAN, I already felt
that something needed to be done. The "perl hashref" templates which I used
to make all those products displayed with only one [HTML::Template](https://metacpan.org/pod/HTML::Template)
template proved to be flexible, extendable and maintainable and that's
exactly from where ZofCMS template format came.

The last site I coded before starting to implement ZofCMS was a private
web application which had a message board along with a few other features.
Mostly everything was coded from scratch once more... The final breaking
point when a few weeks later I was asked to add two sections for file
uploads to that site. No, it wasn't hard to add them, it's just that
I found myself adding a couple lines of code to the "core" modules that
called modules which provided new functionality and those modules were
loaded on any page of the site; even the ones that would never require
functionality from those modules. That's where the idea of plugins came
to life including the idea of "page templates" asking for plugins which
are needed only on that specific page.

After being told at work that I will be putting up about nine sites in
near future I started putting actual ZofCMS code "on paper". The first
"site" was a single page because the content for it was not yet ready, we
just needed "something" to be up. I've used the baby ZofCMS (yet without
any helper scripts) and was quite happy with the ease of installation.
Despite my framework driving just single page being an overkill I already
was prepared for anything which is to be thrown on that site and was
confident that I will no longer have to hack around existing Perl code
on the site.

"What about [Catalyst](https://metacpan.org/pod/Catalyst)?", you may ask. Well, here is my answer.
[Catalyst](https://metacpan.org/pod/Catalyst) is GREAT! I love it. It's magic. But even on
[http://zoffix.com/](http://zoffix.com/), which allows me to easily install modules directly
from CPAN AND gives me ssh access, I spent quite some time deploying
my Catalyst application. As I am not creating very large sites at work
(or at home for that matter) I feel that Catalyst is an overkill for what
I do. I definitely recommend Catalyst to everyone. We make our own choices
\- I am happy with the ones I've made.

# HOW DOES IT WORK

There is a single `index.pl` script. The page to display is specified
via `page` query parameter (it can come from either POST or GET requests).
There is also a `dir` parameter, but it's use it optional. For example,
if you are to access `index.pl?page=foo/bar/baz/page` framework will
convert the query into `page=page&dir=foo/bar/baz/`.

The "config file" (see [App::ZofCMS::Config](https://metacpan.org/pod/App::ZofCMS::Config)) is loaded and checked whether
or not the specified page is an "allowed page"; if it isn't, user will
be presented with a 404.

Later on, the "ZofCMS template" file is located and loaded. This template
is just a file with a Perl hashref in it. All keys have special meanings,
see [App::ZofCMS::Template](https://metacpan.org/pod/App::ZofCMS::Template) for details. Some (or even all) of those keys
can be specified in the "config file" under several keys which provide
"defaults", see [App::ZofCMS::Config](https://metacpan.org/pod/App::ZofCMS::Config) for details.

ZofCMS template will reference a "base" template (which is a
[HTML::Template](https://metacpan.org/pod/HTML::Template) template) as well as several other [HTML::Template](https://metacpan.org/pod/HTML::Template)
files. The framework then will run any plugins, fill out all the values
in the templates and display the page to the user.

# USING THE FRAMEWORK

## FIRST TIME USE

Ok, if you are reading this I can assume you want to give ZofCMS a whirl.
This documentation describes how to install/use it from CPAN. I am also
planing to put up a ZofCMS tarball on [http://web-tools.cc/tools/ZofCMS/](http://web-tools.cc/tools/ZofCMS/)
from which you can get started without touching CPAN (for the most part).
At the time of this writing that webpage is not yet up.

First of all, install `App::ZofCMS` "module" via your cpan script. If you
don't know how to do that, read
[http://novosial.org/perl/life-with-cpan/index.html](http://novosial.org/perl/life-with-cpan/index.html). This will install ZofCMS
"core" along with with helper script. Detailed description of helper
script can be found by running `perldoc zofcms_helper`.

## INITIAL SETUP

Pick a directory in which you want to create ZofCMS "base" from which
you would start working on your site. This documentation assumes that you
are doing all this on a local, fully functional box.

ZofCMS directory/file setup is arranged to have one directory web
accessible; that one will contain `index.pl` along with any CSS/JS files
or images that will be on your website. Another directory will not be
web accessible; here you will keep your ZofCMS templates along with page
templates (i.e. [HTML::Template](https://metacpan.org/pod/HTML::Template), or "data") and the config file.

As example we will want our site to be in `/var/www/testsite/` directory,
thus we go (assuming we are on the system which has `mkdir` and `cd`):

    mkdir /var/www/testsite;
    cd /var/www/testsite/;
    zofcms_helper --site web;

Details about `zofcms_helper` script can be found in
`perldoc zofcms_helper`. In this example, the helper script created two
directories `/var/www/testsite/web/` and `/var/www/testsite/web_site/`.
The `web` directory is what we would have as web accessible (containing
`index.pl`) and `web_site` is what would contain ZofCMS "core".

The helper script stuffed a single file, `index.pl` into
`/var/www/testsite/web/` directory and that's the only thing that ZofCMS
cares about from that directory. **Note:** make sure to remove the line
`use CGI::Carp qw/fatalsToBrowser/;` from `index.pl` before deploying
your finished site live. See `CGI::Carp` for more information.

The `/var/www/testsite/web_site/` has more goodies in it. Here is what we
have in here:

    data        - here you would put your HTML::Template templates which
                  can be references from ZofCMS templates.

    templates   - here is where you would put your ZofCMS templates.

    ZofCMS      - this is where ZofCMS "core", its plugins and
                  any "template exec modules" (more on that later)
                  will live.

In the `data` directory you will notice a file called `base.tmpl` this
is the "base" [HTML::Template](https://metacpan.org/pod/HTML::Template) file, it will be filled with virtually
all the keys from ZofCMS template. In the `templates` directory you will
find `index.tmpl` and `404.tmpl`

**Before we proceed any further** I advise you to read documentation
for [App::ZofCMS::Config](https://metacpan.org/pod/App::ZofCMS::Config) and [App::ZofCMS::Template](https://metacpan.org/pod/App::ZofCMS::Template) as I am not going
to explain what each key means; it is explained in aforementioned
documentation in detail.

## FIRST PAGE

Now, let's create our first page. Let it be named something original,
like "foo" :)

Open up your config file and under valid pages add '/foo'. Considering
you \*did\* read documentation for [App::ZofCMS::Config](https://metacpan.org/pod/App::ZofCMS::Config) you'll know exactly
what to do at this point.

now go to your "core dir" (which will be /var/www/testsite/web\_site/
if you followed (and able to execute) the helper script example from
INITIAL SETUP section above. Go to to directory "templates" and create
a file named `foo.tmpl`, in that file enter the following:

    {
        title       => 'Hello World',
        body        => \'foo.tmpl',
        t           => {
            cur_time => scalar(localtime),
        }
    }

Now go to "data directory" and create a new file named `foo.tmpl` and
enter the following into it:

    <p>Current time is: <tmpl_var name="cur_time">

Providing you did not edit anything else in your config file and did not
touch `base.tmpl` file in your "data directory" you can now access
your web application and see a page which will display current time.
How wonderful \\o/

# REPOSITORY

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

Fork this module on GitHub:
[https://github.com/zoffixznet/App-ZofCMS](https://github.com/zoffixznet/App-ZofCMS)

<div>
    </div></div>
</div>

# BUGS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

To report bugs or request features, please use
[https://github.com/zoffixznet/App-ZofCMS/issues](https://github.com/zoffixznet/App-ZofCMS/issues)

If you can't access GitHub, you can email your request
to `bug-App-ZofCMS at rt.cpan.org`

<div>
    </div></div>
</div>

# AUTHOR

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

<div>
    <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>
</div>

<div>
    </div></div>
</div>

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.
