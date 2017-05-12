# Articulate, a Lightweight Perl CMS Framework

## Synopsis

Articulate provides a content management service for your web app. Lightweight means placing minimal demands on your app while maximising 'whipuptitude': it gives you a single interface in code to a framework that's totally modular underneath, and it won't claim any URL endpoints for itself.

You don't need to redesign your app around Articulate, it's a service that you call on when you need it, and all the 'moving parts' can be switched out if you want to do things your way.

It's written in Perl, the fast, reliable 'glue language' that's perfect for agile web development projects, and currently runs on the Dancer1 and Dancer2 web frameworks.

## Caveat

> Warning:
>
> This is work in progress! It's alpha-stage software and important things WILL change.
>
> If you want a preview, there's an example blog engine included, just clone the repository and type:
>
>     cd examples/plain-speaking
>     bin/app.psgi
>
>  ... and then go to http://localhost:3000/
>
> Don't want a blog? Don't worry, many other things are possible!
>
> Want to know more? The `Development.md` file in the source distribution will get you started working with or on Articulate. Articulate is on CPAN and you can read the documentation at [https://metacpan.org/pod/Articulate](https://metacpan.org/pod/Articulate).

## Who should use Articulate?

Articulate is for you if you need flexibility, or if your requirements often change. Here's some examples of when you might need Articulate:

- If you are starting a new site and expect your content structure and relationships to evolve over time
- If you are going to store rich content with emphasis on semantic value (e.g. e-Learning content), where editing and presentation are distinct concerns
- If you need to associate many metadata fields with your content
- If you already have a website written in one of the supported frameworks and find you have a growing need to manage your static content, then use Articulate as a service within your existing routes

Articulate is a general-purpose tool and you may not want to build your content management solution with Articulate if you have no atypical requirements and your use case can be fully addressed by existing specialised products.

## Roadmap

Articulate is intended to provide a flexible and lightweight core for content management which can be customised using a plugin-based component system.

Articulate uses modern Perl and tries to avoid huge dependencies, while making use of the really good bits of CPAN like Moo, Module::Load and IO::All.

High-level milestones:

- Write some Proof of Concept applications in order to test out the core interface
- Finalise the interfaces as far as possible
- Flesh out the default plugin infrastructure, develop some recommendations for writing plugins

Right now it runs atop Dancer1, and (as of February 2015) Dancer2; support for other frameworks is a goal.

Initial concept work on Articulate started in early 2014 and it was rewritten from scratch in November 2014.
