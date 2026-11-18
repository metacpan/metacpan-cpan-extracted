# The type vocabulary, and which keys are caller data

## Types

    Str  Int  Num  Bool           scalars
    [Str]                         an array of scalars
    [[Str]]                       an array of arrays of scalars
    ['PortBinding']               an array of typed objects
    'HostConfig'                  a single typed object
    { Str, Str }                  a hash whose KEYS ARE CALLER DATA
    { Str, ['PortBinding'] }      same, values are typed

Docker's `definitions:` are flat — there are no groups and no prefix map. A
quoted short name is expanded under `API::Docker::Type::`, and an inline
object nests under its owner (`Mount::BindOptions`). `+Full::Class::Name`
escapes the expansion.

The swagger's `allOf` is not a type but inheritance: `docker_extends 'Resources'`
at the top of the class, which merges the parent's registry entries first so
serialisation keeps the swagger's own field order.

## Keys that are caller data — never translate these

The hash form `{ Str, ... }` marks a field whose keys the user chose. The DSL
must pass those keys through byte for byte. Getting this wrong silently
rewrites user input.

    Labels          arbitrary label names, often dotted: com.example.Some-Label
    Annotations     same
    ExposedPorts    "80/tcp"
    PortBindings    "80/tcp" -> [ { HostIp, HostPort } ]   values ARE typed
    Volumes         "/data" -> {}
    StorageOpt      driver-specific option names
    Tmpfs           mount paths
    Sysctls         kernel parameter names, dotted
    DriverOpts      driver-specific
    Options         volume driver options
    IPAMConfig      inside Networks: subnet/gateway keys are structure, the
                    network names keyed above them are data

Check a field against the spec before assuming: `additionalProperties` in the
swagger is the marker. If the spec says `additionalProperties`, the keys are
data.

## Fields whose type the spec understates

The swagger types some fields as plain strings that are structured in
practice. Record what the spec says, and note the reality in the POD rather
than inventing a type:

    Created         an integer epoch from list, an RFC3339 string from
                    inspect -- measured, both shapes are real
    mode (path stat)  a Go os.FileMode, not a POSIX st_mode word
    Version         a HashRef { Index => N } on swarm objects, not a scalar

When the spec and a measurement disagree, the POD says both and names which
engine and version the measurement came from.
