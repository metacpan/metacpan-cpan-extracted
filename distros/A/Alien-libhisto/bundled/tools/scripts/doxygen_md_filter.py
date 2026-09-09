#!/usr/bin/env python3
"""Doxygen input filter converting GitHub-flavored Markdown LaTeX math delimiters ($/$$)
into native Doxygen formula tags (\\f$/\\f[) while preserving code blocks."""

import sys
import re

def main():
    if len(sys.argv) < 2:
        return
    with open(sys.argv[1], "r", encoding="utf-8", errors="replace") as f:
        content = f.read()

    # Protect code blocks and inline code spans
    parts = []
    last = 0
    code_pattern = re.compile(r"(```.*?```|`.*?`)", re.DOTALL)
    for m in code_pattern.finditer(content):
        text = content[last:m.start()]
        # Convert $$ ... $$ to \f[ ... \f]
        text = re.sub(r"\$\$\s*(.*?)\s*\$\$", r"\n\\f[\n\1\n\\f]\n", text, flags=re.DOTALL)
        # Convert $ ... $ to \f$ ... \f$
        text = re.sub(r"(?<!\\)\$([^\$\n]+?)(?<!\\)\$", r"\\f$\1\\f$", text)
        parts.append(text)
        parts.append(m.group(0))
        last = m.end()
    text = content[last:]
    text = re.sub(r"\$\$\s*(.*?)\s*\$\$", r"\n\\f[\n\1\n\\f]\n", text, flags=re.DOTALL)
    text = re.sub(r"(?<!\\)\$([^\$\n]+?)(?<!\\)\$", r"\\f$\1\\f$", text)
    parts.append(text)

    sys.stdout.write("".join(parts))

if __name__ == "__main__":
    main()
