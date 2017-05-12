# Articulate - Design

This document may be a bit cryptic! It's not a spec and it's not documentation (in the sense of a published interface) but a notepad of design ideas and aspirations, not all of which may come to fruitition.

Some of it is more formal, other bits are more stream-of consciousness.

Since writing much of this, implementation has moved forwards and the docs and bugtracker may be better sources of info.

## Synopsis

Articulate is a Content Management Framework. It provides a service which forms the backbone of your content management solution. Wherever possible the 'moving parts' are replaceable using plugins. It is intended to increase the 'whipuptitude' of the Dancer ecosystem without sacrificing the flexibility you have when writing dancer routes.

Articulate is an expression of the idea that your content management solution is foremost an API:

- it should not place arbitrary restrictions on the front end
- it should not place arbitrary restrictions on role of the content (blog, issue tracker, wiki)
- it should not place arbitrary restrictions on the content-types you want to host, or how you want to edit them
- it should not force you into a url schema you don't want.
- It should be easy to add an Articulate component to a project with other functions.


## Qs

### How to convert a blob to HTML?

The blob must be of a type.

### Can a blob be edited?

Depends on the blob type. If it is a subclass of file, probably not.

If the blob type has an associated edit method - this needs to make the browser load some js and maybe pass some arguments. Eg. load the XML editor and configure it.

### Can a blob be validated?

The blob type needs an associated validator writing.

### Does metadata need validating?

Ultimately yes. It may need to conform to several progressively more restrictive schemas.

### Can we create structured/HTML-encoded results?

Each section has a type.

Groups could be on a zone basis, e.g. public/authors (roles?)

What about Groups of groups, e.g. "developer" across projects

## Technical Specification

### Implementation

Create a content interpreter which gets meta and content together, and does things like run the XSLT. For this we really need the content retrieval to be OO.

The intepreter should be configured with a list of converters.

It will take the content and determine if it can convert the contents into HTML using the tools it has. If it cannot, it will offer a file location for download.

### Components

How are components (sections, comments, etc.) stored, loaded, configured, etc?

Does this include metadata extractors?

Problem: If you load a section, you need to run all the interpreters

Before the response is passed to the template, the components are loaded in order.

$component->process( $response ); # the response is mutated in-place

Components also need to register routes. Do they do so in a separate package? How about a method which modifies the route map?

### Events

An event is when something is done. It is not a hook: there is no possibility of interrupting the event.

### Hooks

A hook is during an execution. It MAY be able to interrupt the action.

hooks->add before_write => sub{ check_permissions }

Do we need hooks when everything is a plugin? What about using things like `around`?

### User Access Control

- Authentication
  - Articulate::Authenticator # finds the user hash and sends it to the authenticator
  - Articulate::Authenticator::Default
  - Articulate::Authenticator::Default->new()->authenticate({user_id=>..., password=>... pw_hash => ... });
- Access Control
  - has_permission ({permission => ?, user => ?, location => ?})

### Architecture summary

- Plack Middleware
- Templating
- Route handlers
- Service handlers
- Components
- Interpreters
- Content Storage
- DB/FS

### Architecture detail

- Plack Middleware
- Templating
- Route handlers
- authentication
- Service handlers - these provide all the API features, including making calls to the authentication layer, components, intperpreters, content storage. Methods are largely like content storage.
  - get_content_raw
- Validation - these are called in series and reject incoming data if invalid. Is authorisation another form of request validation?
- Preservation - these are called in series and are effectively several layers (incoming), adding things like date of deposition
- Augmentation - these are called in series and are effectively several layers (outgoing)
  - augment ($response, $context); # where context is stuff like session, params, etc.
- Interpreters - these are called in parallel, i.e. no more than one on a given piece of content
  - can_interpret ($content_type, $target_type // 'html')
  - intepret ($content_type, $content, $meta, $target_type // 'html')
- Content Storage - must provide:
  - get_item
  - get_item_cached
  - set_item
  - create_item
  - get_content
  - get_content_cached
  - set_content
  - get_meta
  - get_meta_cached
  - set_meta
    patch_meta
  - get_settings
  - get_settings_cached ???
  - set_settings
  - empty_content
  - and indexes??
  - Delete zone? Cascade delete?
- DB/FS

Service handlers are the fulcrum of the application and should not need to be changed much.

The route handlers and templating can be rewritten at will. Components down through content storage are configured like plugins.

### Caching and indexing

The Content component is responsible for caching content, meta, etc, and also clearing the cache when edits are made. This is a low-priority issue to implement.

What about indexing things post-component? e.g. do some metadata extraction to get datesdates, then search? I wonder if indexes need to be maintained separately from content, especially to avoid contamination by non-UGC.

When storage does write ops let it call Indexation which delegates to indexes which can decide whether to update indexes.

What about indexing with a separate service, e.g. store content locally but hive off document search to a solr instance?

### Versioning

Can this be done with an augmentation?

### Content locking

  lock_item ($user, $endtime)

Do this by a plugin? Autolock on get?

### Integrated services

See Articulate::Service

It should be possible to define route handlers, possibly within zones, which are available to only certain users and that perform operations, e.g. authors can access a service which turns markdown into html for previews.

### Items

See Articulate::Item

### Location Object

See Articulate::Location, Articulate::LocationSpecification

A glorified array. Let Redis do zone.public and local do zone/public. Avoid having to deal with initial slashes.

### Setup

Should we have a script like `dancer -a`

articulate -a --preset=empty

  bin
  lib
  content
  indexes
  public
  t

Other presets can be defined like webservice, blog, issue tracker, wiki.

#### Presets

##### Perl Blog Engine "Plain Speaking"

##### Perl Issue Tracker "Pipe Up"

### Error throwing

NotFound => 404

- Case a) NoRoute: no route defined
- Case b) NoResource: a route is defined but one of the ids is wrong
- Case c) NoResult: a search has been performed and there were no results

InputError => 400

  Case a) InputTypeError: a parameter was empty, of the wrong type, etc. and it is not possible to be more specific.
  Case b) InputParsingError: a request has been refused because the content appears broken
  Case c) InputValidationError: A parameter was present, but does not fit with a defined schema.

Conflict => 409

  Case a) The requested action could not be completed because of its effects on other resources
  Case b) The server has decided that requested action should not be completed because it appears that the underlying data has changed since the user last saw the data.

ContentError => 409?

  Case a) There is content on the server which is missing or of the wrong type
  Case b) There is content on the server which is inconsistent
  Case c) There is content on the server which the server does not know how to serve

ServerError => 500

  Case a) An outer layer has sent values that an inner layer cannot understand.
  Case b) An inner layer has sent values that an outer layer cannot understand.
  Case c) A critical layer, component, etc. has actively determined that it is not working and cannot respond to requests meaningfully. .


---

permissions:
  view:
    groups:
    users:
  link:
    groups:
    users:
  edit:
    groups:
    users:
  assign:
    groups:
    users:
meta:
  core:
	history:
		- user:
		  date:
		- user:
		  date:
  schemaorg:
content_type: markdown
