
# CPAN Recent Database

This Beamfile builds a SQLite database for the most recent changes to
CPAN in the last 6 hours.

## Files

### Beamfile

This is Beam::Make's recipe file, in YAML.

### container.yml

This is a [Beam::Wire](http://metacpan.org/pod/Beam::Wire) container
file for configuring objects to be used by the Beamfile recipes.

### cpanfile

This is a [Carton](http://metacpan.org/pod/Carton) file containing the
prerequisites for this example.

## Recipes

### RECENT-6h.json

This downloads the recent file from http://www.cpan.org

### RECENT-6h.csv

This uses `yfrom`, `yq`, and `yto` from
[ETL::Yertl](http://metacpan.org/pod/ETL::Yertl) to convert the JSON
file into a CSV.

### RECENT.db

This builds the SQLite database schema.

### cpan-recent

This loads the `RECENT-6h.csv` file into the `recent` table of the
`RECENT.db` database.

## Installing and Running

To install the prereqs for this example, use
[Carton](http://metacpan.org/pod/Carton).

    $ carton install

To execute this example:

    $ export BEAM_PATH=.
    $ carton exec beam make cpan-recent

