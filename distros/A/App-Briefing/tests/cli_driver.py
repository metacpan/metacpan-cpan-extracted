"""Select the reference Python entrypoint or an external briefing CLI.

BRIEFING_TEST_CLI is a JSON array, for example
["/usr/bin/perl", "-I/absolute/path/to/lib", "/absolute/path/to/script/briefing"].
The configured command is executed as an argv list and receives one of the
public subcommands (hook, doctor, or notice) plus the caller's arguments; it
is never passed to a shell.
"""

import json
import os
import re
import unittest


def command_for(subcommand, default_argv, *arguments):
    """Return the configured CLI plus forwarded argv, or the unchanged fallback."""
    raw = os.environ.get("BRIEFING_TEST_CLI")
    if raw is None:
        return [*default_argv, *arguments]

    try:
        argv = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise RuntimeError("BRIEFING_TEST_CLI must be a JSON argv array") from exc

    if not isinstance(argv, list) or not argv or not all(
        isinstance(item, str) and item for item in argv
    ):
        raise RuntimeError("BRIEFING_TEST_CLI must be a non-empty JSON argv array")

    return [*argv, subcommand, *arguments]


def perl_cli_on_windows():
    """True when the suite drives the Perl CLI (BRIEFING_TEST_CLI) on native Windows."""
    return os.name == "nt" and os.environ.get("BRIEFING_TEST_CLI") is not None


def known_failure_on_windows_perl_cli(card, reason):
    """Mark a test an expected failure on Windows with the Perl CLI only.

    The Python reference hook (no BRIEFING_TEST_CLI) and every other platform keep the
    full claim. expectedFailure rather than skip: once the card is fixed the test
    reports an unexpected success, which is the signal to remove the marker.
    """
    def decorate(test):
        if perl_cli_on_windows():
            test.__doc__ = ((test.__doc__ or "") + "\nKnown failure on Windows with the "
                            "Perl CLI, card %s: %s" % (card, reason)).strip()
            return unittest.expectedFailure(test)
        return test
    return decorate


def assert_skill_dir(testcase, prompt, name, expected):
    """Assert that the <skill name=NAME dir=...> element names the directory EXPECTED.

    Everywhere but Windows the attribute must equal the path text exactly. On Windows one
    directory has several spellings (the 8.3 form C:\\Users\\RUNNER~1 and the long form
    C:\\Users\\runneradmin), so the attribute is compared by directory identity.
    """
    match = re.search(r'<skill name="%s" dir="([^"]*)">' % re.escape(name), prompt)
    testcase.assertIsNotNone(match, "no <skill name=%r dir=...> element in:\n%s" % (name, prompt))
    actual = match.group(1)
    expected = str(expected)
    if os.name != "nt":
        testcase.assertEqual(actual, expected)
        return
    testcase.assertTrue(os.path.isdir(actual),
                        "dir attribute %r is not an existing directory (expected %r)"
                        % (actual, expected))
    testcase.assertTrue(os.path.samefile(actual, expected),
                        "dir attribute %r is not the directory %r" % (actual, expected))
