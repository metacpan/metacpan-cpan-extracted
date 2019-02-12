    README for DTA::CAB

ABSTRACT
    DTA::CAB - "Cascaded Analysis Broker" for error-tolerant linguistic
    analysis

REQUIREMENTS
    Perl Modules
        See "Makefile.PL", "META.json", and/or "META.yml" in the
        distribution directory. Perl dependencies should be available on
        CPAN <http://metacpan.org>.

        Additional Perl modules may be required by particular
        DTA::CAB::Analyzer subclasses. If you see errors like

         Can't locate foo.pm in @INC (you may need to install the foo module)

        ... then you should probably first try looking for the "foo" module
        on on CPAN <http://metacpan.org>.

    External Web-Service
        If you just want to use the client libraries to query an external
        "DTA::CAB" web-service, you'll need only the URL for that service
        and an active internet connection. See the DTA::CAB Web-Service
        HOWTO
        <http://odo.dwds.de/~jurish/software/DTA-CAB/doc/html/DTA.CAB.WebSer
        viceHowto.html> for an introduction.

    Language Resources
        If you want to do anything other than querying an external
        "DTA::CAB" web-service, you'll need a small menagerie of "gfsm"
        transducers and various assorted other language(-variant)-specific
        resources which are not included in this distribution, and for which
        (presumably) there exists no "one-size-fits-all" solution. Look at
        the documentation and code of the individual DTA::CAB::Analyzer
        subclasses you're interested in for more details.

DESCRIPTION
    The DTA::CAB package provides an object-oriented compiler/interpreter
    for error-tolerant heuristic morphological analysis of tokenized text.

INSTALLATION
    Issue the following commands to the shell:

     bash$ cd DTA-CAB-0.01   # (or wherever you unpacked this distribution)
     bash$ perl Makefile.PL  # check requirements, etc.
     bash$ make              # build the module
     bash$ make test         # (optional): test module before installing
     bash$ make install      # install the module on your system

REFERENCES
    If you use this service in an academic context, please include the
    following citation in any related publications:

    *   Jurish, Bryan. *Finite-state Canonicalization Techniques for
        Historical German.* PhD thesis, Universität Potsdam, 2012 (defended
        2011). URN urn:nbn:de:kobv:517-opus-55789, [online
        <http://opus.kobv.de/ubp/volltexte/2012/5578/>, PDF
        <http://kaskade.dwds.de/~jurish/pubs/jurish2012diss.pdf>, BibTeX
        <http://kaskade.dwds.de/~jurish/pubs/jurish2012diss.bib>]

    See here <http://odo.dwds.de/~jurish/software/dta-cab/#pubs> for a list
    of other CAB-related publications.

SEE ALSO
    *   The CAB software page <http://odo.dwds.de/~jurish/software/dta-cab/>
        is the top-level repository for CAB documentation, news, etc.

    *   The DTA::CAB manual page contains a basic introduction to the the
        CAB architecture.

    *   The DTA::CAB::Format manual page describes the abstract CAB I/O
        Format API, and includes a list of supported format classes.

    *   The DTA::CAB::HttpProtocol manual page describes the conventions
        used by the CAB web-service API.

    *   The DTA 'Base Format' Guidelines (DTABf)
        <http://www.deutschestextarchiv.de/doku/basisformat> describes the
        subset of the TEI <http://www.tei-c.org/> encoding guidelines which
        can reasonably be expected to be handled gracefully by the CAB TEI
        and/or TEIws formatters.

AUTHOR
    Bryan Jurish <moocow@cpan.org>

