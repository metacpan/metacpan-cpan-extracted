"""Focused coverage for the external CLI test driver."""

import json
import os
import unittest
from unittest.mock import patch

from cli_driver import command_for


class CliDriverTests(unittest.TestCase):
    def setUp(self):
        self.external_argv = [
            "/opt/perl with spaces/bin/perl",
            "-I/opt/briefing library",
            "/opt/briefing bin/briefing",
        ]

    def test_fallback_keeps_the_existing_python_argv(self):
        fallback = ["python3", "/absolute/path/briefing-preload"]

        with patch.dict(os.environ, {}, clear=True):
            actual = command_for("hook", fallback)

        self.assertEqual(actual, fallback)
        self.assertIsNot(actual, fallback)

    def test_external_hook_selection_preserves_spaced_argv(self):
        with patch.dict(
            os.environ,
            {"BRIEFING_TEST_CLI": json.dumps(self.external_argv)},
            clear=True,
        ):
            actual = command_for("hook", ["python3", "ignored"])

        self.assertEqual(actual, [*self.external_argv, "hook"])

    def test_external_doctor_selection_forwards_arguments_without_shell_splitting(self):
        forwarded = ("--cwd", "/tmp/project with spaces", "--harness", "codex")

        with patch.dict(
            os.environ,
            {"BRIEFING_TEST_CLI": json.dumps(self.external_argv)},
            clear=True,
        ):
            actual = command_for("doctor", ["briefing-doctor"], *forwarded)

        self.assertEqual(actual, [*self.external_argv, "doctor", *forwarded])

    def test_external_notice_selection(self):
        with patch.dict(
            os.environ,
            {"BRIEFING_TEST_CLI": json.dumps(self.external_argv)},
            clear=True,
        ):
            actual = command_for("notice", ["python3", "ignored"])

        self.assertEqual(actual, [*self.external_argv, "notice"])

    def test_malformed_external_configuration_is_rejected(self):
        for raw in ("[", "{}", "[]", '[""]', '["/opt/briefing", 7]'):
            with self.subTest(raw=raw), patch.dict(
                os.environ, {"BRIEFING_TEST_CLI": raw}, clear=True
            ):
                with self.assertRaisesRegex(RuntimeError, "BRIEFING_TEST_CLI"):
                    command_for("hook", ["python3", "ignored"])


if __name__ == "__main__":
    unittest.main()
