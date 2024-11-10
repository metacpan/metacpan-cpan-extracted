static void stop_audio(void)
{
	struct obs_core_audio *audio = &obs->audio;

	if (audio->audio) {
		audio_output_close(audio->audio);
		audio->audio = NULL;
	}
}
