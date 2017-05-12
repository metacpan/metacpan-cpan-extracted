create table revision (
    revnum int primary key
        check (revnum >= 1),
    committed_at timestamp not null
);
create index revision_committed_at on revision (committed_at);

 -- If I could maintain this table automatically, it would avoid the risk of
 -- someone failing to add a branch here before updating the file_path info,
 -- which might conceivablt break the GUIDs.  Perhaps I could have a file
 -- with a special name, say '_top', to mark the top directory of each branch.
create table branch (
    id serial primary key,

    -- Relative path from repository root URL to right trunk/branch/whatever.
    path text not null unique
        check ((path = 'trunk' or path like 'branches/%' or path like 'tags/%')
               and path not like '%/')
);

insert into branch (path) values ('trunk');

create table working_copy (
    id serial primary key,
    branch_id int not null references branch,

    -- Revision currently represented by the working copy.
    -- This is never less than 1, because the first revision (to create
    -- the 'trunk' directory, etc.) has to be done before we can check out.
    current_revision int not null references revision
        check (current_revision >= 1)
);

create table file_guid (
    id serial primary key,
    is_dir boolean not null,
    uri text not null unique
        check (uri similar to '[a-z][-+.a-z0-9]*:%'),

    -- If the 'daizu:guid' property is added to a file on the trunk then
    -- the 'uri' field above is set to its value, but the standard URI
    -- is saved in 'old_uri' so that if the property is removed then it
    -- will go back to having the same URI as it used to.  A standard
    -- URI is always generated, even for files which had 'daizu:guid'
    -- right from the start.
    old_uri text
        check (uri similar to '[a-z][-+.a-z0-9]*:%'),
    custom_uri boolean not null default false,
    constraint file_guid_old_uri_missing_chk
        check (custom_uri = (old_uri is not null)),

    first_revnum int not null references revision
        check (first_revnum >= 1),
    -- This ignores changes outside the trunk, and deletions.
    last_changed_revnum int not null references revision
        check (first_revnum >= 1),
    constraint file_guid_revnum_chk
        check (last_changed_revnum >= first_revnum)
);

create table file_path (
    guid_id int not null references file_guid,
    path text not null
        check (path <> '' and path not like '/%' and path not like '%/'),
    branch_id int not null references branch,
    first_revnum int not null references revision
        check (first_revnum >= 1),
    last_revnum int references revision
        check (last_revnum >= 1),
    constraint file_path_bad_revnums_chk
        check (last_revnum >= first_revnum),
    primary key (guid_id, branch_id, first_revnum)
);
create index file_path_path_idx on file_path (path);
create unique index file_path_unique_idx on file_path (branch_id, path, first_revnum);

create table wc_file (
    id serial primary key,
    wc_id int not null references working_copy on delete cascade,
    guid_id int not null references file_guid,
    parent_id int references wc_file on delete cascade,
    is_dir boolean not null,
    name text not null
        check (name <> '' and name <> '.' and name <> '..' and
               name not like '%/%'),
    path text not null  -- redundant, but probably useful
        check (path <> '' and path not like '/%' and path not like '%/'),
    constraint wc_file_bad_path_and_name_chk
        check (path = name or path like ('%/' || name)),

    -- Revision number the file is based on and changes which have been made
    -- in respect to what is in the repository for that revision.
    -- cur_revnum is null for files which have been added but not yet committed.
    cur_revnum int references revision,
    modified boolean not null default false,
    deleted boolean not null default false,
    constraint wc_file_cur_revnum_missing_chk
        check (cur_revnum is not null or (not modified and not deleted)),

    -- Class name of this file's generator.  Either directly from the
    -- 'daizu:generator' property, or inherited from its parent, or taking
    -- the default value.
    generator text not null
        check (generator similar to '[\\_a-zA-Z][-\\_:a-zA-Z0-9]*[\\_a-zA-Z0-9]'),
    -- Files which are their own root file have this set to NULL.  Other
    -- files have it pointing to one of their ancestors, whichever is the
    -- closest to have a 'daizu:generator' property.
    root_file_id int references wc_file on delete cascade,

    custom_url text     -- daizu:url
        check (custom_url similar to '[a-z][-+.a-z0-9]*:%'),

    article boolean not null default false,     -- 'article' type
    retired boolean not null default false,     -- 'retired' flag
    no_index boolean not null default false,    -- 'no-index' flag

    issued_at timestamp not null,
    modified_at timestamp not null,

    title text,
    short_title text,
    description text,
    content_type text
        -- All ASCII characters allowed except 'tspecials' defined in RFC 2045.
        check (content_type similar to '[-!#$\\%&''*+.0-9A-Z^\\_`a-z{|}~]+/[-!#$\\%&''*+.0-9A-Z^\\_`a-z{|}~]+'),
    -- TODO - character encoding - for now just assume everything's UTF8

    -- These two only apply to image files, and are here to avoid having
    -- to look in the file's content everytime we want to generate a page
    -- which references it.
    image_width int check (image_width > 0),
    image_height int check (image_height > 0),

    -- The actual binary contents of the file, or a reference to another
    -- file whose data is the same (to save space if there are multiple
    -- working copies, since most files will have the same data in each WC).
    -- The reference should be to the version of the file in the live WC.
    --
    -- If data_from_file_id is non-NULL, the file it references must have
    -- a non-NULL 'data' field.
    -- The live working copy must not use data_from_file_id.
    --
    -- For directories:
    --      data_len must be 0 and the other two NULL.
    -- For files:
    --      exactly one of data and data_from_file_id must be non-NULL.
    -- For empty files:
    --      data must be '' and data_from_file_id NULL.
    --
    -- data_sha1 is the SHA1 digest of the data.  It must be NULL for
    -- directories, and non-NULL for files.  The 160 bit digest must be
    -- encoded as 27 characters in base 64 format, with the single
    -- padding '=' stripped off.
    data_from_file_id int references wc_file,
    data bytea,
    data_len int not null
        check (data_len >= 0),
    data_sha1 char(27)
        check (length(data_sha1) = 27 and
               data_sha1 similar to '[A-Za-z0-9+/]+'),
    constraint wc_file_wrong_data_len_chk
        check (data_len = length(data)),
    constraint wc_file_bad_dir_data_chk
        check (not is_dir or
               (data_from_file_id is null and data is null and
                data_len = 0 and data_sha1 is null)),
    constraint wc_file_bad_file_data_chk
        check (is_dir or
               (data_sha1 is not null and
                ((data is not null and data_from_file_id is null) or
                 (data is null and data_from_file_id is not null)))),
    constraint wc_file_bad_empty_file_data_chk
        check (is_dir or data_len > 0 or data is not null),

    -- These values are NULL for files which aren't articles.
    article_pages_url text,     -- absolute URL, can be used as permalink
    article_content text,
    constraint wc_file_article_loaded_chk
        check ((article and article_content is not null and
                            article_pages_url is not null) or
               (not article and article_content is null and
                                article_pages_url is null))
);
create unique index wc_file_path_idx on wc_file (wc_id, path);

create table wc_property (
    file_id int not null references wc_file on delete cascade,
    name text not null check (name <> ''),
    value text not null,
    modified boolean not null default false,    -- modified or added
    deleted boolean not null default false,
    primary key (file_id, name)
);

create table tag (
    tag text primary key
        check (tag <> '')
);

create table wc_file_tag (
    file_id int not null references wc_file on delete cascade,
    tag text not null references tag,   -- Canonicalized spelling.
    original_spelling text not null,    -- As specified in daizu:tags.
    primary key (file_id, tag)
);

create table wc_article_extra_url (
    file_id int not null references wc_file on delete cascade,
    url text not null,
    content_type text not null
        -- All ASCII characters allowed except 'tspecials' defined in RFC 2045.
        check (content_type similar to '[-!#$\\%&''*+.0-9A-Z^\\_`a-z{|}~]+/[-!#$\\%&''*+.0-9A-Z^\\_`a-z{|}~]+'),
    generator text not null
        check (generator similar to '[\\_a-zA-Z][-\\_:a-zA-Z0-9]*[\\_a-zA-Z0-9]'),
    method text not null
        check (method similar to '[\\_a-zA-Z0-9]+'),
    argument text not null default ''
);

create table wc_article_extra_template (
    file_id int not null references wc_file on delete cascade,
    filename text not null
);

create table wc_article_included_files (
    file_id int not null references wc_file on delete cascade,
    included_file_id int not null
        references wc_file deferrable initially deferred
);

create table url (
    id serial primary key,
    url text not null
        check (url similar to '[a-z][-+.a-z0-9]*:%'),
    wc_id int not null references working_copy on delete cascade,
    guid_id int not null references file_guid,
    generator text not null
        check (generator similar to '[\\_a-zA-Z][-\\_:a-zA-Z0-9]*[\\_a-zA-Z0-9]'),
    method text not null
        check (method similar to '[\\_a-zA-Z0-9]+'),
    argument text not null default '',
    content_type text
        -- All ASCII characters allowed except 'tspecials' defined in RFC 2045.
        check (content_type similar to '[-!#$\\%&''*+.0-9A-Z^\\_`a-z{|}~]+/[-!#$\\%&''*+.0-9A-Z^\\_`a-z{|}~]+'),
    status char(1) not null
        -- Active, Redirect, Gone
        check (status in ('A', 'R', 'G')),

    -- If the status is 'R' then this indicates which entry in the 'url'
    -- table this one should redirect to.  The target URL may be gone, but
    -- it should not be another redirect.
    redirect_to_id int references url,
    constraint url_redirect_missing_chk
        check ((status = 'R') = (redirect_to_id is not null))
);
create unique index url_unique_idx on url (url, wc_id);

create table live_revision (
    revnum int not null references revision
);

 -- TODO - allow for a seperate Latin transliterated name, e.g. for Chinese
create table person (
    id serial primary key,
    username text not null unique       -- UTF-8
        check (username !~ '\s')
);

create table person_info (
    person_id int not null references person on delete cascade,
    path text not null,
    name text not null,                 -- UTF-8
    email text,
    uri text,                           -- person's homepage, or whatever
    primary key (person_id, path)
);

create table file_author (
    file_id int not null references wc_file on delete cascade,
    person_id int not null references person,
    pos int not null,   -- sort on this to get order authors were specified in
    primary key (file_id, person_id)
);

 -- vi:ts=4 sw=4 expandtab
