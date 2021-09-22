#! /usr/bin/env python

import sys
import time
import chess

def perft(pos, depth):
	nodes = 0
	for move in pos.legal_moves:
		pos.push(move)

		if depth > 1:
			nodes += perft(pos, depth - 1)
		else:
			nodes += 1

		pos.pop()

	return nodes

def perftWithOutput(pos, depth):
	nodes = 0
	started = time.time()
	for move in pos.legal_moves:
		subnodes = 0

		print(move, end=': ')
		pos.push(move)

		if depth > 1:
			subnodes = perft(pos, depth - 1)
		else:
			subnodes = 1

		pos.pop()

		print(subnodes)
		nodes += subnodes

	elapsed = time.time() - started
	nps = '+INF'
	if elapsed:
		nps = int(0.5 + nodes / elapsed)
	print(f'info nodes: {nodes} ({elapsed} s, nps: {nps})')

depth = sys.argv[1]

pos = chess.Board()
perftWithOutput(pos, int(depth))
